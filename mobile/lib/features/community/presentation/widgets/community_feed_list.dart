import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/presentation/widgets/community_card.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:flutter/material.dart';

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
  });

  final List<CommunityPost> posts;
  final double bottomPad;
  final FeedViewMode mode;
  final ScrollController controller;
  final Color accentColor;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String postId) onLike;
  final Future<void> Function(String postId) onBookmark;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return RefreshIndicator(
        color: accentColor,
        backgroundColor: AppColors.bgSurface,
        onRefresh: onRefresh,
        child: ListView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 32, 16, bottomPad),
          children: [
            SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  'No posts in this section yet.',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 13,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isCardMode = mode == FeedViewMode.card;
    return RefreshIndicator(
      color: accentColor,
      backgroundColor: AppColors.bgSurface,
      onRefresh: onRefresh,
      child: ListView.separated(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
        itemCount: posts.length,
        separatorBuilder: (_, __) => isCardMode
            ? const SizedBox(height: 10)
            : Divider(
                height: 1,
                color: AppColors.borderSubtle.withValues(alpha: 0.8),
              ),
        itemBuilder: (context, index) => CommunityCard(
          post: posts[index],
          mode: mode,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.communityDiscussion,
            arguments: posts[index].id,
          ),
          onCommentTap: () => Navigator.of(context).pushNamed(
            AppRoutes.communityDiscussion,
            arguments: {
              'postId': posts[index].id,
              'focusComposer': true,
            },
          ),
          onLike: () => onLike(posts[index].id),
          onBookmark: () => onBookmark(posts[index].id),
        ),
      ),
    );
  }
}
