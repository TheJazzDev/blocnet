import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_tab_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_feed_sliver.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/new_updates_pill.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/core/home_bootstrap_payload.dart';
import 'package:blocnet/services/core/home_bootstrap_store.dart';
import 'package:blocnet/services/core/startup_metrics_service.dart';
import 'package:blocnet/services/edge/edge_engine_store.dart';
import 'package:blocnet/features/projects/presentation/models/feed_blend.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/presentation/models/quiet_gem.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_caught_up_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_day_one.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_radar_strip.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/shared/application/feed/feed_sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

part 'home/home_hydration.part.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with _HomeHydration {
  /// Set only when the member taps a tab themselves. Null means "follow the
  /// data".
  Section? _pickedSection;

  /// The tab on screen.
  ///
  /// Until the member picks one this tracks the follow count every build
  /// rather than being locked in once. Follows arrive from the network after
  /// the first frame, so a default decided on build one always saw zero and
  /// pinned every member to *For you*, including someone with a full board.
  /// See [FeedBlend.defaultsToFollowing]: a thin board opens on *For you*,
  /// which mixes in curated gems, and a filled one opens on *Following*.
  Section _section = Sections.forYou;
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
    if (_section == section) return;
    setState(() {
      _pickedSection = section;
      _section = section;
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
    if (!mounted) return;

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

  /// The hunters worth showing a member who follows nothing, ranked by how
  /// much they have posted. Five, because the design's rail is five.
  List<FeedHunter> _topHunters(UpdatesStore store) {
    final counts = <String, int>{};
    final names = <String, FeedHunter>{};
    for (final post in store.posts) {
      final admin = post.admin;
      if (admin == null) continue;
      final raw = admin.username.trim().replaceAll('@', '');
      final handle = raw.isEmpty
          ? '@${admin.id.substring(0, admin.id.length >= 6 ? 6 : admin.id.length)}'
          : '@$raw';
      counts[handle] = (counts[handle] ?? 0) + 1;
      names[handle] = (handle: handle, name: admin.name, admin: admin);
    }
    final ranked = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return ranked.take(5).map((h) => names[h]!).toList();
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
    final updatesStore = context.watch<UpdatesStore>();
    // select, not watch: this screen needs one field from each of these, and
    // AuthStore in particular notifies from ~56 places that cannot change the
    // feed. watch() rebuilt the whole feed on every one of them.
    final feedViewMode =
        context.select<FeedViewModeStore, FeedViewMode>((store) => store.mode);
    final isInHunterSpace =
        context.select<AuthStore, bool>((auth) => auth.isInHunterSpace);
    final accent = AppColors.accentForSpace(isInHunterSpace);
    // Choose the opening tab the first time we know the follow count.
    final followCount =
        context.watch<ProjectsStore>().followedProjectIds.length;
    _section = _pickedSection ??
        (FeedBlend.defaultsToFollowing(followCount)
            ? Sections.following
            : Sections.forYou);
    // Earned, not idle: only claim this once the radar has actually reported,
    // the member has a board to be caught up on, and nothing is pending.
    final radar = _radarSummary;
    // Computed here rather than in the feed because the caught-up card depends
    // on it: a board with an unkept gem is not a covered board, whatever the
    // radar says about new updates.
    final quietGems = QuietGems.detect(
      projects: context.watch<ProjectsStore>().projects,
      followedProjectIds: context.watch<ProjectsStore>().followedProjectIds,
      posts: updatesStore.posts,
      now: DateTime.now(),
    );
    final showCaughtUp = quietGems.isEmpty &&
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
                    dimFollowing: followCount == 0,
                  ),
                ),
                const SliverToBoxAdapter(child: AppSpace.gapMd),
                // One radar panel above the feed, or the caught-up panel in its
                // place when nothing is waiting. The old separate Alpha Radar
                // and Edge Engine panels pushed the first post too far down.
                if (showCaughtUp)
                  _TopPanel(
                    child: FeedCaughtUpCard(
                      accent: accent,
                      gemsFollowed: followCount,
                      updatesTracked: _trackedUpdateCount(
                        updatesStore,
                        context.read<ProjectsStore>().followedProjectIds,
                      ),
                      sweptAt: radar.asOf,
                    ),
                  )
                // Not on day one: "0 new across 0 gems" is noise on a screen
                // whose whole job is to get the member their first follow.
                else if (radar != null && followCount > 0)
                  _TopPanel(
                    child: FeedRadarStrip(radar: radar, accent: accent),
                  ),
                HomeFeedSliver(
                  activeSection: _section,
                  quietGems: quietGems,
                  topHunters: _topHunters(updatesStore),
                  showCaughtUp: showCaughtUp,
                  isInitialLoading: feedLoading,
                  feedViewMode: feedViewMode,
                ),
                SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
              ],
            ),
          ),
          if (_pendingNewPostIds.isNotEmpty)
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

/// A panel above the feed, inside the screen gutter with a gap beneath it.
class _TopPanel extends StatelessWidget {
  const _TopPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        0,
        AppSpace.lg,
        AppSpace.md,
      ),
      sliver: SliverToBoxAdapter(child: child),
    );
  }
}
