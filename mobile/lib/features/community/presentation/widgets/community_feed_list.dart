import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_card.dart';
import 'package:blocnet/features/community/presentation/widgets/community_content_moderation_sheet.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/shared/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';

/// One topic's posts, pull to refresh. When there are none it says why:
/// nothing posted yet, or the feed failed to load.
class CommunityFeedList extends StatelessWidget {
  const CommunityFeedList({
    super.key,
    required this.posts,
    required this.bottomPad,
    required this.mode,
    required this.controller,
    required this.accentColor,
    required this.onRefresh,
    required this.onLike,
    required this.onBookmark,
    this.onModeratePost,
    this.canArchiveModeration = false,
    this.error,
    this.emptyTitle = 'No posts yet',
  });

  final List<CommunityPost> posts;
  final double bottomPad;
  final FeedViewMode mode;
  final ScrollController controller;
  final Color accentColor;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String postId) onLike;
  final Future<void> Function(String postId) onBookmark;
  final Future<void> Function(
    String postId,
    CommunityContentModerationDecision decision,
  )? onModeratePost;
  final bool canArchiveModeration;

  /// Why the feed failed to load; shown only when there is nothing to list.
  final String? error;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: accentColor,
      backgroundColor: AppColors.bgSurface,
      onRefresh: onRefresh,
      child: posts.isEmpty ? _empty() : _list(context),
    );
  }

  Widget _empty() {
    return ListView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPad),
      children: [
        error != null
            ? AppEmptyState.error(
                title: 'Couldn’t load posts',
                message: error,
                onAction: onRefresh,
              )
            : AppEmptyState(
                icon: Icons.forum_outlined,
                title: emptyTitle,
                message: 'Tap + to start one.',
              ),
      ],
    );
  }

  Widget _list(BuildContext context) {
    final isCard = mode == FeedViewMode.card;
    return ListView.separated(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        isCard ? AppSpace.md : 0,
        AppSpace.lg,
        bottomPad,
      ),
      itemCount: posts.length,
      separatorBuilder: (_, __) => isCard
          ? const SizedBox(height: AppSpace.md)
          : const Divider(height: 1, color: AppColors.borderSubtle),
      itemBuilder: (context, index) {
        final post = posts[index];
        return CommunityCard(
          key: ValueKey('community-post-${post.id}'),
          post: post,
          mode: mode,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.communityDiscussion,
            arguments: post.id,
          ),
          onCommentTap: () => Navigator.of(context).pushNamed(
            AppRoutes.communityDiscussion,
            arguments: {'postId': post.id, 'focusComposer': true},
          ),
          onLike: () => onLike(post.id),
          onBookmark: () => onBookmark(post.id),
          onModerate: onModeratePost == null
              ? null
              : (decision) => onModeratePost!(post.id, decision),
          canArchiveModeration: canArchiveModeration,
        );
      },
    );
  }
}
