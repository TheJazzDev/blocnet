import 'package:blocnet/features/community/application/community_comment_threading.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'community_fakes.dart';

void main() {
  group('threadCommunityComments', () {
    List<String> shape(List<ThreadedCommunityComment> items) => [
          for (final i in items)
            '${i.isNestedReply ? '  ' : ''}${i.comment.id}',
        ];

    test('puts replies, and replies to replies, under their root', () {
      final thread = threadCommunityComments([
        comment(id: 'a'),
        comment(id: 'b'),
        comment(id: 'a1', replyToId: 'a'),
        comment(id: 'a1x', replyToId: 'a1'), // used to vanish
        comment(id: 'b1', replyToId: 'b'),
      ]);
      expect(shape(thread), ['a', '  a1', '  a1x', 'b', '  b1']);
    });

    test('keeps a reply to an unloaded comment at the top level', () {
      final thread = threadCommunityComments([
        comment(id: 'x', replyToId: 'missing'),
        comment(id: 'y'),
      ]);
      expect(shape(thread), ['x', 'y']);
    });

    test('never drops comments that reply in a loop', () {
      final thread = threadCommunityComments([
        comment(id: 'p', replyToId: 'q'),
        comment(id: 'q', replyToId: 'p'),
        comment(id: 's', replyToId: 's'),
      ]);
      expect(thread.map((i) => i.comment.id).toSet(), {'p', 'q', 's'});
    });
  });

  group('CommunityPostsStore', () {
    late FakePostsRepository repo;
    late CommunityPostsStore store;

    setUp(() {
      repo = FakePostsRepository();
      store = CommunityPostsStore(repository: repo);
    });

    test('opening a post outside the feed does not add it to the feed',
        () async {
      repo.feed = [post(id: 'feed')];
      await store.refreshPosts();
      repo.byId = (id) => post(id: id, content: 'Old post');

      final opened = await store.fetchPostById('old');

      expect(opened?.id, 'old');
      expect(store.postById('old')?.content, 'Old post');
      expect(store.posts.map((p) => p.id), ['feed']);
    });

    test('a post that cannot be opened reports why', () async {
      repo.byIdError = ApiException('Post not found', statusCode: 404);
      expect(await store.fetchPostById('gone'), isNull);
      expect(store.postLoadError('gone'), 'Post not found');

      repo.byIdError = null;
      repo.byId = (_) => null;
      await store.fetchPostById('gone');
      expect(store.postLoadError('gone'), 'This post is no longer available');
    });

    test('a failed feed load is kept apart from action errors', () async {
      repo.feedError = ApiException('Server is down', statusCode: 503);
      await store.refreshPosts();
      expect(store.postsError, isNot(contains('Server is down')));

      repo.feedError = null;
      repo.feed = [post(id: 'p1')];
      await store.refreshPosts();
      expect(store.postsError, isNull);

      repo.toggleError = ApiException('nope', statusCode: 500);
      expect(await store.toggleBookmark('p1'), isFalse);
      expect(store.lastError, 'Could not update saved');
      expect(store.postsError, isNull);
      expect(store.postById('p1')!.isBookmarked, isFalse); // rolled back
    });

    test('blocking an author clears their posts everywhere', () async {
      final blocked = author(id: 'bad', name: 'Spammer');
      repo.feed = [post(id: 'p1', by: blocked), post(id: 'p2')];
      repo.bookmarks = [post(id: 'p3', by: blocked, saved: true)];
      await store.refreshPosts();
      await store.loadSavedPosts();

      store.removeContentByAuthor('bad');

      expect(store.posts.map((p) => p.id), ['p2']);
      expect(store.savedPosts, isEmpty);
    });

    test('removing a moderated post drops it from feed and saved', () async {
      repo.feed = [post(id: 'p1', saved: true)];
      repo.bookmarks = [post(id: 'p1', saved: true)];
      await store.refreshPosts();
      await store.loadSavedPosts();

      store.removePost('p1');

      expect(store.posts, isEmpty);
      expect(store.savedPosts, isEmpty);
      expect(store.postById('p1'), isNull);
    });

    test('a toggle already in flight is ignored, not reported as failed',
        () async {
      repo.feed = [post(id: 'p1')];
      await store.refreshPosts();
      final first = store.toggleBookmark('p1');
      expect(await store.toggleBookmark('p1'), isNull);
      expect(await first, isTrue);
      expect(await store.toggleBookmark('unknown'), isNull);
    });
  });
}
