import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/presentation/sections/explore/explore.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/catch_up_banner.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/empty_feed.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_skeletons.dart';
import 'package:blocnet/features/projects/presentation/models/feed_blend.dart';
import 'package:blocnet/features/projects/presentation/models/quiet_gem.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_quiet_gem_card.dart';
import 'package:blocnet/services/edge/edge_engine_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
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
    required this.quietGems,
  });

  final Section activeSection;
  final bool isInitialLoading;
  final bool showCatchupFilter;
  final RadarSummary? radarSummary;
  final FeedViewMode feedViewMode;
  final VoidCallback onClearCatchup;

  /// Followed gems whose hunter has gone quiet. Computed once by the screen,
  /// because the caught-up card has to know about them too — claiming a member
  /// is covered while a card below says otherwise is a contradiction.
  final List<QuietGem> quietGems;

  @override
  Widget build(BuildContext context) {
    return Consumer3<UpdatesStore, EdgeEngineStore, ProjectsStore>(
      builder: (context, store, edgeStore, projectsStore, _) {
        final enrichedPosts = store.posts
            .where((post) => post.project != null && post.admin != null)
            .toList();
        final radarLastSeenAt = radarSummary?.lastSeenAt;
        final feedPosts = showCatchupFilter
            ? enrichedPosts.where((post) {
                final isUnseen = radarLastSeenAt == null
                    ? true
                    : post.createdAt.isAfter(radarLastSeenAt);
                final isHighPriority =
                    post.priority.label.toLowerCase() == 'high';
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

        if (activeSection == Sections.forYou ||
            activeSection == Sections.following) {
          if (isInitialLoading && enrichedPosts.isEmpty) {
            return const _FeedLoadingPlaceholder();
          }
          if (store.isFetching && store.posts.isEmpty) {
            return const _FeedLoadingPlaceholder();
          }

          // Following shows only the member's own gems. For you mixes theirs
          // with curated ones, in a proportion that shifts as their board
          // fills, so Home is worth scrolling on day one and is almost all
          // theirs by the tenth follow. See [FeedBlend].
          final followedIds = projectsStore.followedProjectIds;
          final followed = rankedFeedPosts
              .where((post) => followedIds.contains(post.projectId))
              .toList();
          final curated = rankedFeedPosts
              .where((post) => !followedIds.contains(post.projectId))
              .toList();
          final posts = activeSection == Sections.following
              ? followed
              : FeedBlend.blend(
                  followed: followed,
                  curated: curated,
                  followCount: followedIds.length,
                );

          // A followed gem nobody has touched in two weeks is the product's
          // real failure mode, and nothing used to surface it. These cards sit
          // in the stream, above the updates, because a missing update is the
          // most important thing on the board when it happens.
          //
          // Shown on both feed tabs, not just Following: a gem going quiet is
          // about the member's own board, and it matters wherever they are
          // looking. Capped at three so a neglected board does not bury the
          // feed under warnings.
          final quietCards = quietGems
              .take(3)
              .map(
                (gem) => FeedQuietGemCard(
                  gem: gem,
                  onUnfollow: () =>
                      projectsStore.toggleFollowProject(gem.project.id),
                  onAsk: () => _ask(context, projectsStore, gem),
                  onReport: () => _report(context, projectsStore, gem),
                ),
              )
              .toList();

          if (posts.isEmpty && quietCards.isEmpty) {
            return const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppSpace.lg),
              sliver: SliverToBoxAdapter(child: EmptyFeed()),
            );
          }
          // Card rows are full-bleed and carry their own padding, so the feed
          // reads as one stream rather than a stack of floating panels. The
          // list layout has not been redesigned and still wants a gutter.
          final isFullBleed = feedViewMode == FeedViewMode.card;
          return SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isFullBleed ? 0 : AppSpace.lg,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (showCatchupFilter)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isFullBleed ? AppSpace.lg : 0,
                    ),
                    child: CatchUpBanner(onClear: onClearCatchup),
                  ),
                ...quietCards,
                ..._buildFeedRows(posts, feedViewMode),
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
    return const SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSpace.lg),
      sliver: SliverToBoxAdapter(child: FeedSkeleton()),
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

/// Asks a gem's hunter for an update and says what happened.
///
/// The server aggregates, so the useful confirmation is how many members are
/// waiting rather than "sent" — it tells the member their tap joined a count
/// the hunter will actually see.
Future<void> _ask(
  BuildContext context,
  ProjectsStore store,
  QuietGem gem,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final waiting = await store.requestUpdateOn(gem.project.id);
  if (!context.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        waiting == null
            ? 'You have already asked about this gem recently.'
            : waiting == 1
                ? 'Asked. You are the first waiting on ${gem.project.name}.'
                : 'Asked. $waiting members are waiting on ${gem.project.name}.',
      ),
    ),
  );
}

/// Reports a gem as unmaintained, after confirming.
///
/// Confirmed because it puts another member's standing in question, and the
/// copy says plainly what happens next so nobody expects an instant handover.
Future<void> _report(
  BuildContext context,
  ProjectsStore store,
  QuietGem gem,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.bgSurface,
      title: Text('Report ${gem.project.name}?'),
      content: const Text(
        'A moderator will review whether this gem needs a new hunter. '
        'It is not reassigned automatically.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Report'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final open = await store.reportProjectInactive(gem.project.id);
  if (!context.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        open == null
            ? 'Could not send that report. Try again shortly.'
            : 'Reported. A moderator will review ${gem.project.name}.',
      ),
    ),
  );
}
