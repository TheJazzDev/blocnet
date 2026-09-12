import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/engagement/data/models/edge_brief_model.dart';
import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/features/main/presentation/widgets/main_tab_scope.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:blocnet/features/projects/presentation/pages/edge_engine_page.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/alpha_radar_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/edge_brief_teaser_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_tab_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_feed_sliver.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/new_updates_pill.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/top_hunters_row.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/core/home_bootstrap_payload.dart';
import 'package:blocnet/services/core/home_bootstrap_store.dart';
import 'package:blocnet/services/core/startup_metrics_service.dart';
import 'package:blocnet/services/edge/edge_engine_store.dart';
import 'package:blocnet/features/projects/presentation/models/feed_blend.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_caught_up_card.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/shared/application/feed/feed_sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

part 'home/home_edge_actions.part.dart';
part 'home/home_hydration.part.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with _HomeHydration, _HomeEdgeActions {
  /// Null until the first build knows how many gems the member follows, so
  /// the opening tab can be chosen rather than guessed. See
  /// [FeedBlend.defaultsToFollowing]: a thin board opens on *For you*, which
  /// mixes in curated gems, and a full one opens on *Following*.
  Section? _activeSection;
  Section get _section => _activeSection ?? Sections.forYou;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _pendingNewPostIds = <String>{};
  final FeedSyncController _feedSyncController =
      FeedSyncController(debugLabel: 'Home');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    StartupMetricsService.markHomeShellReady();

    // Paint whatever the bootstrap cache holds before the first frame; the
    // network refresh runs after it in the post-frame callback.
    _applyCachedBootstrapSync();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _hydrateHomeProgressively();
    });
    _feedSyncController.start(
      realtimeEnabled: AppConfig.isSupabaseConfigured,
      pollInterval: const Duration(seconds: 12),
      channelName: 'home-new-updates',
      table: 'Update',
      onSyncRequested: _checkForNewPosts,
    );
  }

  @override
  void dispose() {
    _feedSyncController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged(Section section) {
    if (_activeSection == section) return;
    setState(() {
      _activeSection = section;
      if (section == Sections.explore) {
        _pendingNewPostIds.clear();
        _showCatchupFilter = false;
      }
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset <= 20) {
      if (_pendingNewPostIds.isNotEmpty) {
        setState(() => _pendingNewPostIds.clear());
      }
      _ackRadarSeen();
    }
  }

  Future<void> _checkForNewPosts() async {
    // Both feed tabs care about new posts; only General does not.
    if (!mounted || _section == Sections.explore) {
      return;
    }

    final updatesStore = context.read<UpdatesStore>();
    final existingIds = updatesStore.posts.map((post) => post.id).toSet();

    await updatesStore.refreshUpdates();

    if (!mounted) return;

    final refreshedPosts = updatesStore.posts;
    final newIds = refreshedPosts
        .where((post) => !existingIds.contains(post.id))
        .map((post) => post.id)
        .toSet();

    if (newIds.isEmpty) return;

    final isNearTop =
        _scrollController.hasClients && _scrollController.offset < 80;
    if (isNearTop) return;

    setState(() {
      _pendingNewPostIds.addAll(newIds);
    });
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _jumpToLatest() async {
    await _scrollToTop();
    if (!mounted) return;
    setState(() => _pendingNewPostIds.clear());
  }

  void _onCatchUpTap() {
    if (!mounted) return;
    setState(() {
      _activeSection = Sections.following;
      _showCatchupFilter = true;
    });
    unawaited(_scrollToTop());
  }

  /// Updates on the member's board — those belonging to a gem they follow.
  /// Used by the caught-up receipt, which only ever states numbers the app
  /// genuinely knows.
  int _trackedUpdateCount(UpdatesStore store, Set<String> followedIds) {
    return store.posts
        .where((post) => followedIds.contains(post.projectId))
        .length;
  }

  Future<void> _handlePullToRefresh() async {
    await _refreshAllSections();
    if (!mounted) return;
    setState(() => _pendingNewPostIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 96;
    final edgeStore = context.watch<EdgeEngineStore>();
    final updatesStore = context.watch<UpdatesStore>();
    final feedViewMode = context.watch<FeedViewModeStore>().mode;
    final isInHunterSpace = context.watch<AuthStore>().isInHunterSpace;
    final accent = AppColors.accentForSpace(isInHunterSpace);
    // Choose the opening tab the first time we know the follow count.
    final followCount =
        context.watch<ProjectsStore>().followedProjectIds.length;
    _activeSection ??= FeedBlend.defaultsToFollowing(followCount)
        ? Sections.following
        : Sections.forYou;
    final isForYou = _section != Sections.explore;
    // Earned, not idle: only claim this once the radar has actually reported,
    // the member has a board to be caught up on, and nothing is pending.
    final radar = _radarSummary;
    final showCaughtUp = isForYou &&
        !_isLoadingRadar &&
        radar != null &&
        !radar.hasUpdates &&
        followCount > 0 &&
        _pendingNewPostIds.isEmpty;
    final feedLoading = !_isFeedReady &&
        updatesStore.posts.isEmpty &&
        (_isBootstrapLoading || updatesStore.isFetching);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          RefreshIndicator(
            color: accent,
            backgroundColor: AppColors.bgSurface,
            onRefresh: _handlePullToRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: FeedTabDelegate(
                    activeSection: _section,
                    onTabChanged: _onTabChanged,
                  ),
                ),
                const SliverToBoxAdapter(child: AppSpace.gapMd),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                  sliver: SliverToBoxAdapter(
                    // Being caught up is the product delivering its promise, so
                    // it gets its own earned card rather than the same grey
                    // panel that carries a pending count. The radar card stays
                    // for the case where something *is* waiting.
                    child: showCaughtUp
                        ? FeedCaughtUpCard(
                            accent: accent,
                            gemsFollowed: followCount,
                            updatesTracked: _trackedUpdateCount(
                              updatesStore,
                              context.read<ProjectsStore>().followedProjectIds,
                            ),
                            sweptAt: _radarSummary?.asOf,
                          )
                        : AlphaRadarCard(
                            radar: _radarSummary,
                            isLoading: _isLoadingRadar,
                            onCatchUp: _onCatchUpTap,
                          ),
                  ),
                ),
                const SliverToBoxAdapter(child: AppSpace.gapMd),
                if (isForYou) ...[
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                    sliver: SliverToBoxAdapter(
                      child: EdgeBriefTeaserCard(
                        brief: edgeStore.brief,
                        isLoading:
                            (edgeStore.isFetching || _isBootstrapLoading) &&
                                edgeStore.brief == null,
                        onOpen: _openEdgeEnginePage,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: AppSpace.gapMd),
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                    sliver: SliverToBoxAdapter(
                      child: TopHuntersRow(isLoading: feedLoading),
                    ),
                  ),
                  const SliverToBoxAdapter(child: AppSpace.gapMd),
                ],
                HomeFeedSliver(
                  activeSection: _section,
                  isInitialLoading: feedLoading,
                  showCatchupFilter: _showCatchupFilter,
                  radarSummary: _radarSummary,
                  feedViewMode: feedViewMode,
                  onClearCatchup: () {
                    setState(() => _showCatchupFilter = false);
                  },
                ),
                SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
              ],
            ),
          ),
          if (isForYou && _pendingNewPostIds.isNotEmpty)
            NewUpdatesPill(
              count: _pendingNewPostIds.length,
              backgroundColor: accent,
              textColor: AppColors.onAccentForSpace(isInHunterSpace),
              onTap: _jumpToLatest,
            ),
        ],
      ),
    );
  }
}
