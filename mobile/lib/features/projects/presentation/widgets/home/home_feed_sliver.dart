import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/presentation/sections/explore/explore.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/catch_up_banner.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/empty_feed.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card.dart';
import 'package:blocnet/services/edge/edge_engine_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeFeedSliver extends StatelessWidget {
  const HomeFeedSliver({
    super.key,
    required this.activeSection,
    required this.isInitialLoading,
    required this.showCatchupFilter,
    required this.radarSummary,
    required this.feedViewMode,
    required this.onClearCatchup,
  });

  final Section activeSection;
  final bool isInitialLoading;
  final bool showCatchupFilter;
  final RadarSummary? radarSummary;
  final FeedViewMode feedViewMode;
  final VoidCallback onClearCatchup;

  @override
  Widget build(BuildContext context) {
    return Consumer2<UpdatesStore, EdgeEngineStore>(
      builder: (context, store, edgeStore, _) {
        final enrichedPosts = store.posts
            .where((post) => post.project != null && post.admin != null)
            .toList();
        final radarLastSeenAt = radarSummary?.lastSeenAt;
        final feedPosts = showCatchupFilter
            ? enrichedPosts.where((post) {
                final isUnseen = radarLastSeenAt == null
                    ? true
                    : post.createdAt.isAfter(radarLastSeenAt);
                final isHighPriority = post.priority.label.toLowerCase() == 'high';
                return isUnseen || isHighPriority;
              }).toList()
            : enrichedPosts;
        final rankedFeedPosts = [...feedPosts]..sort((a, b) {
            final scoreA = edgeStore.edgeScoreForUpdate(a.id);
            final scoreB = edgeStore.edgeScoreForUpdate(b.id);

            if (scoreA != null || scoreB != null) {
              if (scoreA == null) return 1;
              if (scoreB == null) return -1;
              final byScore = scoreB.compareTo(scoreA);
              if (byScore != 0) return byScore;
            }

            return b.createdAt.compareTo(a.createdAt);
          });

        if (activeSection == Sections.forYou) {
          if (isInitialLoading && enrichedPosts.isEmpty) {
            return const _FeedLoadingPlaceholder();
          }
          if (store.isFetching && store.posts.isEmpty) {
            return const _FeedLoadingPlaceholder();
          }
          if (rankedFeedPosts.isEmpty) {
            return const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: EmptyFeed()),
            );
          }
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (showCatchupFilter) CatchUpBanner(onClear: onClearCatchup),
                ..._buildFeedRows(rankedFeedPosts, feedViewMode),
              ]),
            ),
          );
        }

        return SliverToBoxAdapter(
          child: ExploreSection(
            allPosts: store.posts,
            feedViewMode: feedViewMode,
          ),
        );
      },
    );
  }
}

class _FeedLoadingPlaceholder extends StatelessWidget {
  const _FeedLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
          ),
        ),
      ),
    );
  }
}

List<Widget> _buildFeedRows(List<Update> posts, FeedViewMode viewMode) {
  if (viewMode == FeedViewMode.card) {
    return posts.map((post) => FeedCard(post: post)).toList();
  }

  final rows = <Widget>[];
  for (var index = 0; index < posts.length; index++) {
    rows.add(
      FeedCard(
        post: posts[index],
        layout: FeedCardLayout.list,
      ),
    );
    if (index < posts.length - 1) {
      rows.add(
        Divider(
          height: 1,
          color: AppColors.borderSubtle.withValues(alpha: 0.8),
        ),
      );
    }
  }
  return rows;
}
