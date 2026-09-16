import 'dart:async';

import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/projects/legacy_update_reactions_sync.dart';
import 'package:blocnet/services/projects/update_reactions_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reactions_fixtures.dart';

void main() {
  late FakeReactionsRepository repo;
  late UpdateReactionsStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = FakeReactionsRepository();
    store = UpdateReactionsStore(repository: repo);
  });

  group('like toggle', () {
    test('reads the server state off the update when nothing was toggled', () {
      final post = reactionUpdate(likedByMe: true, likesCount: 9);
      expect(store.isLiked(post), isTrue);
      expect(store.likesCount(post), 9);
    });

    test('flips at once, then settles on the count the server returns',
        () async {
      final post = reactionUpdate(likesCount: 412);
      repo
        ..likeGate = Completer<void>()
        ..serverLikes = 420;

      final pending = store.toggleLike(post);
      expect(store.isLiked(post), isTrue, reason: 'optimistic');
      expect(store.likesCount(post), 413, reason: 'optimistic');

      repo.likeGate!.complete();
      expect(await pending, isTrue);
      expect(store.isLiked(post), isTrue);
      expect(store.likesCount(post), 420, reason: 'server count wins');
      expect(repo.calls, ['PUT like update-1']);
    });

    test('reverts and rethrows when the server call fails', () async {
      final post = reactionUpdate(likesCount: 412);
      repo
        ..likeGate = Completer<void>()
        ..failWrites = true;

      final pending = store.toggleLike(post);
      expect(store.isLiked(post), isTrue);

      repo.likeGate!.complete();
      await expectLater(pending, throwsA(isA<ApiException>()));
      expect(store.isLiked(post), isFalse);
      expect(store.likesCount(post), 412);
    });

    test('a revert returns to the previous toggle, not to the snapshot',
        () async {
      final post = reactionUpdate(likesCount: 412);
      repo.serverLikes = 413;
      await store.toggleLike(post);

      repo.failWrites = true;
      await expectLater(store.toggleLike(post), throwsA(isA<ApiException>()));
      expect(store.isLiked(post), isTrue);
      expect(store.likesCount(post), 413);
    });

    test('unlike sends DELETE and never goes below zero optimistically',
        () async {
      final post = reactionUpdate(likedByMe: true, likesCount: 0);
      repo.likeGate = Completer<void>();

      final pending = store.toggleLike(post);
      expect(store.isLiked(post), isFalse);
      expect(store.likesCount(post), 0);
      repo.likeGate!.complete();
      await pending;
      expect(repo.calls, ['DELETE like update-1']);
    });

    test('ignores a second tap while the first is in flight', () async {
      final post = reactionUpdate();
      repo.likeGate = Completer<void>();

      final first = store.toggleLike(post);
      final second = await store.toggleLike(post);
      expect(second, isTrue, reason: 'answers the current state');
      repo.likeGate!.complete();
      await first;
      expect(repo.calls, hasLength(1));
    });

    test('drops its override once a refreshed update agrees with it', () async {
      final stale = reactionUpdate(likesCount: 412);
      repo.serverLikes = 413;
      await store.toggleLike(stale);
      expect(store.likesCount(stale), 413);

      // The feed refetched: someone else liked it too.
      final fresh = reactionUpdate(likedByMe: true, likesCount: 500);
      expect(store.isLiked(fresh), isTrue);
      expect(store.likesCount(fresh), 500);
      // And the override is gone, so the stale snapshot is shown as-is again.
      expect(store.isLiked(stale), isFalse);
    });

    test('notifies listeners for the optimistic flip and the settle', () async {
      var notified = 0;
      store.addListener(() => notified++);
      await store.toggleLike(reactionUpdate());
      expect(notified, 2);
    });
  });

  group('bookmark toggle', () {
    test('flips at once, settles on the server count', () async {
      final post = reactionUpdate(bookmarksCount: 7);
      repo
        ..bookmarkGate = Completer<void>()
        ..serverBookmarks = 8;

      final pending = store.toggleBookmark(post);
      expect(store.isBookmarked(post), isTrue);
      expect(store.bookmarksCount(post), 8);
      repo.bookmarkGate!.complete();
      expect(await pending, isTrue);
      expect(repo.calls, ['PUT bookmark update-1']);
    });

    test('reverts when the server call fails', () async {
      final post = reactionUpdate(bookmarksCount: 7);
      repo.failWrites = true;

      await expectLater(
        store.toggleBookmark(post),
        throwsA(isA<ApiException>()),
      );
      expect(store.isBookmarked(post), isFalse);
      expect(store.bookmarksCount(post), 7);
    });
  });

  group('saved list', () {
    test('reads the saved updates from the server', () async {
      repo.saved = [
        reactionUpdate(id: 'u2', title: 'Second', bookmarkedByMe: true),
        reactionUpdate(id: 'u1', title: 'First', bookmarkedByMe: true),
      ];

      await store.refreshSaved();

      expect(store.savedUpdates.map((u) => u.id), ['u2', 'u1']);
      expect(store.hasLoadedSaved, isTrue);
      expect(repo.calls, ['GET saved']);
    });

    test('keeps the error and loads nothing when the read fails', () async {
      repo.failSaved = true;
      await store.refreshSaved();
      expect(store.savedUpdates, isEmpty);
      expect(store.savedError, isNotNull);
      expect(store.hasLoadedSaved, isFalse);
    });

    test('unsaving removes the row, and a failure puts it back in place',
        () async {
      final a = reactionUpdate(id: 'a', bookmarkedByMe: true);
      final b = reactionUpdate(id: 'b', bookmarkedByMe: true);
      repo.saved = [a, b];
      await store.refreshSaved();

      repo
        ..bookmarkGate = Completer<void>()
        ..failWrites = true;
      final pending = store.toggleBookmark(a);
      expect(store.savedUpdates.map((u) => u.id), ['b']);

      repo.bookmarkGate!.complete();
      await expectLater(pending, throwsA(isA<ApiException>()));
      expect(store.savedUpdates.map((u) => u.id), ['a', 'b']);
      expect(store.isBookmarked(a), isTrue);
    });

    test('saving from the feed puts the update on top of a loaded list',
        () async {
      repo.saved = [reactionUpdate(id: 'old', bookmarkedByMe: true)];
      await store.refreshSaved();

      await store.toggleBookmark(reactionUpdate(id: 'new'));
      expect(store.savedUpdates.map((u) => u.id), ['new', 'old']);
    });
  });

  group('account scope', () {
    test('a different member starts from a clean slate', () async {
      store.ensureUserScope('member-a');
      repo.saved = [reactionUpdate(id: 'a-saved', bookmarkedByMe: true)];
      await store.refreshSaved();
      final post = reactionUpdate();
      await store.toggleLike(post);

      store.ensureUserScope('member-b');
      expect(store.savedUpdates, isEmpty);
      expect(store.hasLoadedSaved, isFalse);
      expect(store.isLiked(post), isFalse);
    });

    test('starts the one-time import once for a signed-in member', () async {
      SharedPreferences.setMockInitialValues({
        LegacyUpdateReactionsSync.likesKey: ['u1'],
      });
      store = UpdateReactionsStore(repository: repo);

      store.ensureUserScope(null);
      store.ensureUserScope('member-a');
      store.ensureUserScope('member-a');
      await pumpEventQueue();

      expect(repo.calls.where((c) => c == 'POST import'), hasLength(1));
    });

    test('refreshes a loaded Saved list after importing', () async {
      SharedPreferences.setMockInitialValues({
        LegacyUpdateReactionsSync.bookmarksKey: ['u1'],
      });
      store = UpdateReactionsStore(repository: repo);
      await store.refreshSaved();
      repo.calls.clear();

      final outcome = await store.syncLegacyReactions();

      expect(outcome, LegacySyncOutcome.imported);
      expect(repo.calls, ['POST import', 'GET saved']);
    });
  });
}
