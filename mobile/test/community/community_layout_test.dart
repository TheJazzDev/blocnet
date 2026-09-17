import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_card.dart';
import 'package:blocnet/features/community/presentation/widgets/community_discussion_composer.dart';
import 'package:blocnet/features/community/presentation/widgets/discussion/discussion_thread_list.dart';
import 'package:blocnet/features/mentions/data/repositories/mentions_repository.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'community_fakes.dart';

/// A post and a thread at 375px (iPhone SE width). In `flutter test` a
/// RenderFlex overflow is an exception, so these fail on any overflow.
void main() {
  late CommunityPostsStore store;

  setUp(() {
    store = CommunityPostsStore(repository: FakePostsRepository());
  });

  final longAuthor = author(
    name: 'Bartholomew Montgomery-Fitzgerald the Third of Lagos',
    username: 'bartholomew_montgomery_fitzgerald_iii',
    roles: const ['hunter'],
    level: 42,
  );
  final longBody = List.filled(
    30,
    'Mainnet snapshot moved to 12:00 UTC, @ada_lovelace_the_first check it.',
  ).join(' ');

  for (final mode in FeedViewMode.values) {
    testWidgets('a long post fits at 375px in ${mode.name} mode',
        (tester) async {
      usePhone(tester);
      await tester.pumpWidget(
        communityHost(
          store: store,
          wrapInScaffold: true,
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              CommunityCard(
                post: post(
                  by: longAuthor,
                  content: longBody,
                  likes: 123456,
                  comments: 98765,
                  saved: true,
                  liked: true,
                  status: CommunityContentModerationStatus.archived,
                ),
                mode: mode,
                onTap: () {},
                onLike: () {},
                onCommentTap: () {},
                onBookmark: () {},
                onModerate: (_) async {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Bartholomew Montgomery-Fitzgerald the Third of Lagos'),
        findsOneWidget,
      );
      // With room the role pill shows; on the narrower card line it gives
      // way to the name instead of overflowing.
      expect(
        find.text('HUNTER'),
        mode == FeedViewMode.list ? findsOneWidget : findsNothing,
      );
      expect(find.text('ARCHIVED'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
      // The body is clamped in lists; the discussion shows the rest.
      final body = tester.widget<Text>(
        find.byWidgetPredicate(
          (w) => w is Text && w.textSpan?.toPlainText() == longBody,
        ),
      );
      expect(body.maxLines, CommunityCard.bodyLines);
      expect(body.overflow, TextOverflow.ellipsis);
    });
  }

  testWidgets('a thread with replies and a composer fits at 375px',
      (tester) async {
    usePhone(tester);
    final root = comment(
      id: 'c1',
      by: longAuthor,
      content: longBody.substring(0, 400),
    );
    final orphanReply = comment(
      id: 'c4',
      replyToId: 'gone',
      replyTo: ReplyToData(
        id: 'gone',
        content: longBody,
        username: 'someone_with_a_really_long_username_indeed',
      ),
    );
    final comments = [
      root,
      comment(id: 'c2', replyToId: 'c1', by: longAuthor),
      comment(id: 'c3', replyToId: 'c2', content: longBody.substring(0, 200)),
      orphanReply,
    ];
    final controller = TextEditingController(text: 'Hello');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);

    await tester.pumpWidget(
      communityHost(
        store: store,
        wrapInScaffold: true,
        child: Column(
          children: [
            Expanded(
              child: DiscussionThreadList(
                post: post(
                  by: longAuthor,
                  content: longBody.substring(0, 300),
                  comments: 1,
                ),
                comments: comments,
                controller: ScrollController(),
                isLoadingComments: false,
                hasMoreComments: true,
                commentsError: null,
                onLoadOlder: () {},
                onRetryComments: () {},
                onLikePost: () {},
                onSavePost: () {},
                onCommentTap: () {},
                onLikeComment: (_) {},
                onReply: (_) {},
                onModeratePost: (_) async {},
                onModerateComment: (_, __) async {},
              ),
            ),
            CommunityDiscussionComposer(
              controller: controller,
              focusNode: focus,
              mentionsRepository: MentionsRepository(ApiClient()),
              isSending: false,
              onSendTap: () {},
              replyingToUsername: 'bartholomew_montgomery_fitzgerald_iii_x',
              onCancelReply: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The count is the post's (1) or the loaded list's (4), whichever is more.
    expect(find.text('COMMENTS · 4'), findsOneWidget);
    expect(find.text('Load older'), findsOneWidget);

    // Scroll through every comment so each one is laid out.
    for (final id in ['c1', 'c2', 'c3', 'c4']) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('comment-$id')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: id);
    }
    expect(find.textContaining('Replying to @someone_with'), findsOneWidget);
  });
}
