import 'dart:async';

import 'package:blocnet/features/community/presentation/pages/community_saved_screen.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'community_fakes.dart';

/// The Saved view: posts saved to `/me/bookmarks`, which used to be shown
/// nowhere.
void main() {
  late FakePostsRepository repo;
  late CommunityPostsStore store;

  setUp(() {
    repo = FakePostsRepository();
    store = CommunityPostsStore(repository: repo);
  });

  Future<void> pumpSaved(WidgetTester tester) async {
    usePhone(tester);
    await tester.pumpWidget(
      communityHost(child: const CommunitySavedScreen(), store: store),
    );
  }

  testWidgets('shows a spinner while loading, then the saved posts',
      (tester) async {
    repo.bookmarksGate = Completer<void>();
    repo.bookmarks = [
      post(id: 'a', content: 'First saved post', saved: true),
      post(id: 'b', content: 'Second saved post', saved: true),
    ];

    await pumpSaved(tester);
    await tester.pump();
    expect(find.byKey(const ValueKey('saved-loading')), findsOneWidget);
    expect(find.text('First saved post'), findsNothing);

    repo.bookmarksGate!.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('saved-loading')), findsNothing);
    expect(find.text('First saved post'), findsOneWidget);
    expect(find.text('Second saved post'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget); // the title
    expect(repo.bookmarkCalls, 1);
  });

  testWidgets('says so when nothing is saved', (tester) async {
    repo.bookmarks = [];
    await pumpSaved(tester);
    await tester.pumpAndSettle();

    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('saved-loading')), findsNothing);
  });

  testWidgets('shows the error and retries', (tester) async {
    repo.bookmarksError = ApiException('Server is down', statusCode: 503);
    await pumpSaved(tester);
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t load saved posts'), findsOneWidget);
    expect(find.text('Server is down'), findsNothing);

    repo.bookmarksError = null;
    repo.bookmarks = [post(id: 'a', content: 'Back again', saved: true)];
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repo.bookmarkCalls, 2);
    expect(find.text('Back again'), findsOneWidget);
    expect(find.text('Couldn’t load saved posts'), findsNothing);
  });

  testWidgets('unsaving a post removes it from the list', (tester) async {
    repo.bookmarks = [
      post(id: 'a', content: 'Keep me', saved: true),
      post(id: 'b', content: 'Drop me', saved: true),
    ];
    await pumpSaved(tester);
    await tester.pumpAndSettle();

    final dropCard = find.byKey(const ValueKey('saved-post-b'));
    await tester.tap(
      find.descendant(of: dropCard, matching: find.bySemanticsLabel('Unsave')),
    );
    await tester.pumpAndSettle();

    expect(repo.unsaved, ['b']);
    expect(find.text('Drop me'), findsNothing);
    expect(find.text('Keep me'), findsOneWidget);
    expect(store.savedPosts.map((p) => p.id), ['a']);
    await tester.pump(const Duration(seconds: 4)); // let the toast expire
  });

  testWidgets('a failed unsave puts the post back', (tester) async {
    repo.bookmarks = [post(id: 'a', content: 'Sticky', saved: true)];
    await pumpSaved(tester);
    await tester.pumpAndSettle();

    repo.toggleError = ApiException('nope', statusCode: 500);
    await tester.tap(find.bySemanticsLabel('Unsave'));
    await tester.pumpAndSettle();

    expect(find.text('Sticky'), findsOneWidget);
    expect(find.text('Could not update saved'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  test('saving a feed post adds it to a loaded Saved list', () async {
    repo.feed = [post(id: 'f', content: 'From the feed')];
    await store.refreshPosts();
    await store.loadSavedPosts();
    expect(store.savedPosts, isEmpty);

    expect(await store.toggleBookmark('f'), isTrue);
    expect(store.savedPosts.map((p) => p.id), ['f']);
    expect(store.postById('f')!.isBookmarked, isTrue);

    expect(await store.toggleBookmark('f'), isTrue);
    expect(store.savedPosts, isEmpty);
    expect(repo.saved, ['f']);
    expect(repo.unsaved, ['f']);
  });
}
