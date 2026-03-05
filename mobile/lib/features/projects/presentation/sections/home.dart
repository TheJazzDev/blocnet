import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/engagement/data/models/edge_brief_model.dart';
import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:blocnet/features/projects/presentation/pages/edge_engine_page.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/alpha_radar_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/edge_brief_teaser_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_feed_sliver.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_tab_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/new_updates_pill.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/top_hunters_row.dart';
import 'package:blocnet/shared/application/feed/feed_sync_controller.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/edge/edge_engine_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/core/home_bootstrap_service.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/core/startup_metrics_service.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Section _activeSection = Sections.forYou;
  bool _isFeedReady = false;
  bool _isEdgeReady = false;
  bool _isBootstrapLoading = false;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _pendingNewPostIds = <String>{};
  final UsersApiRepository _usersRepository = UsersApiRepository();
  final HomeBootstrapService _homeBootstrapService = HomeBootstrapService();
  final FeedSyncController _feedSyncController =
      FeedSyncController(debugLabel: 'Home');
  RadarSummary? _radarSummary;
  bool _isLoadingRadar = true;
  bool _isAcknowledgingRadar = false;
  bool _showCatchupFilter = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    StartupMetricsService.markHomeShellReady();
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
      if (section != Sections.forYou) {
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
    if (!mounted || _activeSection != Sections.forYou) {
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

  Future<void> _jumpToLatest() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    setState(() => _pendingNewPostIds.clear());
  }

  Future<void> _loadRadar() async {
    if (!mounted) return;
    setState(() => _isLoadingRadar = true);

    try {
      final radar = await _usersRepository.fetchRadar();
      if (!mounted) return;
      setState(() => _radarSummary = radar);
    } catch (_) {
      if (!mounted) return;
      setState(() => _radarSummary = null);
    } finally {
      if (mounted) {
        setState(() => _isLoadingRadar = false);
      }
    }
  }

  Future<void> _ackRadarSeen() async {
    final radar = _radarSummary;
    if (_isAcknowledgingRadar || radar == null || !radar.hasUpdates) {
      return;
    }

    _isAcknowledgingRadar = true;
    try {
      await _usersRepository.ackRadar();
      if (!mounted) return;
      setState(() {
        _radarSummary = RadarSummary(
          asOf: DateTime.now(),
          lastSeenAt: DateTime.now(),
          newUpdatesCount: 0,
          highUrgencyCount: 0,
          activeProjects: const [],
        );
        _showCatchupFilter = false;
      });
    } catch (_) {
      // Keep existing radar state; next refresh can recover.
    } finally {
      _isAcknowledgingRadar = false;
    }
  }

  void _onCatchUpTap() {
    if (!mounted) return;
    setState(() {
      _activeSection = Sections.forYou;
      _showCatchupFilter = true;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _handleRefresh() async {
    final projectsStore = context.read<ProjectsStore>();
    final updatesStore = context.read<UpdatesStore>();
    final edgeStore = context.read<EdgeEngineStore>();
    await Future.wait([
      projectsStore.refreshProjects(),
      updatesStore.refreshUpdates(),
      edgeStore.refresh(),
    ]);
    await _loadRadar();

    if (!mounted) return;
    setState(() {
      _pendingNewPostIds.clear();
      _showCatchupFilter = false;
      _isFeedReady = updatesStore.posts.isNotEmpty;
      _isEdgeReady = edgeStore.brief != null;
    });
  }

  Future<void> _hydrateHomeProgressively() async {
    if (!mounted) return;
    setState(() => _isBootstrapLoading = true);

    final updatesStore = context.read<UpdatesStore>();
    final edgeStore = context.read<EdgeEngineStore>();
    final projectsStore = context.read<ProjectsStore>();

    try {
      final cached = await _homeBootstrapService.loadCached();
      if (cached != null && mounted) {
        _applyBootstrapPayload(
          cached,
          updatesStore: updatesStore,
          edgeStore: edgeStore,
          projectsStore: projectsStore,
        );
      }
    } catch (_) {
      // Best effort cache restore.
    }

    HomeBootstrapPayload? remotePayload;
    try {
      remotePayload = await _homeBootstrapService.fetchHomeBootstrap(
        feedLimit: 100,
        windowDays: 7,
      );
      if (remotePayload != null && mounted) {
        _applyBootstrapPayload(
          remotePayload,
          updatesStore: updatesStore,
          edgeStore: edgeStore,
          projectsStore: projectsStore,
        );
        await _homeBootstrapService.saveCached(remotePayload);
      }
    } catch (_) {
      // Fallback to existing per-section loading below.
    }

    try {
      final futures = <Future<void>>[
        projectsStore.fetchProjectsOnce(),
        remotePayload == null || remotePayload.feedItems.isEmpty
            ? updatesStore.fetchUpdatesOnce()
            : updatesStore.refreshUpdates(),
        remotePayload == null || remotePayload.edgeBrief == null
            ? edgeStore.fetchOnce()
            : edgeStore.refresh(),
        _loadRadar(),
      ];

      await Future.wait(futures);
      if (!mounted) return;

      setState(() {
        _isFeedReady = updatesStore.posts.isNotEmpty;
        _isEdgeReady = edgeStore.brief != null;
      });

      if (_isFeedReady) {
        StartupMetricsService.markHomeFeedReady();
      }
      if (_isEdgeReady) {
        StartupMetricsService.markEdgeReady();
      }
    } finally {
      if (mounted) {
        setState(() => _isBootstrapLoading = false);
      }
    }
  }

  void _applyBootstrapPayload(
    HomeBootstrapPayload payload, {
    required UpdatesStore updatesStore,
    required EdgeEngineStore edgeStore,
    required ProjectsStore projectsStore,
  }) {
    unawaited(
      projectsStore.hydrateFollowStateFromMeSummary(
        payload.meSummary,
        notify: false,
      ),
    );
    updatesStore.hydrateFromUpdates(payload.feedItems, notify: false);
    edgeStore.hydrateBrief(payload.edgeBrief, notify: false);

    setState(() {
      _radarSummary = payload.radar ?? _radarSummary;
      _isLoadingRadar = payload.radar == null;
      _isFeedReady = payload.feedItems.isNotEmpty;
      _isEdgeReady = payload.edgeBrief != null;
    });

    if (_isFeedReady) {
      StartupMetricsService.markHomeFeedReady();
    }
    if (_isEdgeReady) {
      StartupMetricsService.markEdgeReady();
    }
  }

  Future<void> _sendEdgeFeedback(
    EdgeBriefDecision decision,
    String action,
  ) async {
    final edgeStore = context.read<EdgeEngineStore>();
    final ok = await edgeStore.sendFeedback(
      decisionId: decision.decisionId,
      action: action,
      context: const {
        'surface': 'home_edge_brief',
      },
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'BEE feedback saved: ${action.toUpperCase()}'
              : 'Failed to submit BEE feedback',
        ),
      ),
    );
  }

  Future<void> _openEdgeExplain(EdgeBriefDecision decision) async {
    final edgeStore = context.read<EdgeEngineStore>();
    final explain = await edgeStore.fetchExplain(decision.decisionId);
    if (!mounted) return;

    if (explain == null || !explain.hasExplanation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load BEE explanation')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => EdgeExplainSheet(explain: explain),
    );
  }

  Future<void> _openEdgeEnginePage() async {
    final edgeStore = context.read<EdgeEngineStore>();
    if (edgeStore.brief == null && !edgeStore.isFetching) {
      await edgeStore.refresh();
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EdgeEnginePage(
          onAction: _sendEdgeFeedback,
          onExplain: _openEdgeExplain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 96;
    final edgeStore = context.watch<EdgeEngineStore>();
    final feedViewMode = context.watch<FeedViewModeStore>().mode;
    final accent =
        AppColors.accentForSpace(context.watch<AuthStore>().isInHunterSpace);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          RefreshIndicator(
            color: accent,
            backgroundColor: AppColors.bgSurface,
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: FeedTabDelegate(
                    activeSection: _activeSection,
                    onTabChanged: _onTabChanged,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: AlphaRadarCard(
                      radar: _radarSummary,
                      isLoading: _isLoadingRadar,
                      onCatchUp: _onCatchUpTap,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (_activeSection == Sections.forYou) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: EdgeBriefTeaserCard(
                        brief: edgeStore.brief,
                        isLoading: (edgeStore.isFetching || _isBootstrapLoading) &&
                            edgeStore.brief == null,
                        onOpen: _openEdgeEnginePage,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
                if (_activeSection == Sections.forYou) ...[
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(child: TopHuntersRow()),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
                HomeFeedSliver(
                  activeSection: _activeSection,
                  isInitialLoading:
                      !_isFeedReady && context.watch<UpdatesStore>().posts.isEmpty,
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
          if (_activeSection == Sections.forYou &&
              _pendingNewPostIds.isNotEmpty)
            NewUpdatesPill(
              count: _pendingNewPostIds.length,
              backgroundColor: accent,
              textColor: AppColors.onAccentForSpace(
                context.watch<AuthStore>().isInHunterSpace,
              ),
              onTap: _jumpToLatest,
            ),
        ],
      ),
    );
  }
}
