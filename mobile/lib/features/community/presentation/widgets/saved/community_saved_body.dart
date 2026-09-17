import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/community/presentation/widgets/community_card.dart';
import 'package:blocnet/features/community/presentation/widgets/feed/community_save_toggle.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:blocnet/shared/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Loading, failed, empty, or the list of saved posts. Unsaving a post (its
/// bookmark) takes it off the list.
class CommunitySavedBody extends StatelessWidget {
  const CommunitySavedBody({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommunityPostsStore>();
    final posts = store.savedPosts;

    if (posts.isEmpty) {
      if (store.isLoadingSaved ||
          (!store.hasLoadedSaved && store.savedError == null)) {
        return Center(
          key: const ValueKey('saved-loading'),
          child: CircularProgressIndicator(
            color: AppColors.primary400,
            strokeWidth: 2,
          ),
        );
      }
      if (store.savedError != null) {
        return Center(
          child: AppEmptyState.error(
            title: 'Couldn’t load saved posts',
            message: store.savedError,
            onAction: store.loadSavedPosts,
          ),
        );
      }
      return RefreshIndicator(
        color: AppColors.primary400,
        backgroundColor: AppColors.bgSurface,
        onRefresh: store.loadSavedPosts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            AppEmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'Nothing saved yet',
              message: 'Tap the bookmark on a post to keep it here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary400,
      backgroundColor: AppColors.bgSurface,
      onRefresh: store.loadSavedPosts,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          MediaQuery.paddingOf(context).bottom + AppSpace.xl,
        ),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpace.md),
        itemBuilder: (context, index) {
          final post = posts[index];
          return CommunityCard(
            key: ValueKey('saved-post-${post.id}'),
            post: post,
            mode: FeedViewMode.card,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.communityDiscussion,
              arguments: post.id,
            ),
            onCommentTap: () => Navigator.of(context).pushNamed(
              AppRoutes.communityDiscussion,
              arguments: {'postId': post.id, 'focusComposer': true},
            ),
            onLike: () => store.toggleLike(post.id),
            onBookmark: () => toggleCommunitySave(context, post.id),
          );
        },
      ),
    );
  }
}
