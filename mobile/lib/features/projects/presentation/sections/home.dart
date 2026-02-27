import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/engagement/data/models/edge_brief_model.dart';
import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/presentation/pages/edge_engine_page.dart';
import 'package:blocnet/features/projects/presentation/sections/explore/explore.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/alpha_radar_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/catch_up_banner.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/edge_brief_teaser_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/empty_feed.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_tab_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/top_hunters_row.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/edge_engine_store.dart';
import 'package:blocnet/services/feed_view_mode_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Section _activeSection = Sections.forYou;
  bool _isInitialLoading = true;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _pendingNewPostIds = <String>{};
  final UsersApiRepository _usersRepository = UsersApiRepository();
  Timer? _newPostsPollTimer;
  RealtimeChannel? _newPostsRealtimeChannel;
  bool _isCheckingForNewPosts = false;
  RadarSummary? _radarSummary;
  bool _isLoadingRadar = true;
  bool _isAcknowledgingRadar = false;
  bool _showCatchupFilter = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final projectsStore = context.read<ProjectsStore>();
      final updatesStore = context.read<UpdatesStore>();
      final edgeStore = context.read<EdgeEngineStore>();
      await projectsStore.fetchProjectsOnce();
      await updatesStore.fetchUpdatesOnce();
      await edgeStore.fetchOnce();
      await _loadRadar();
      if (!mounted) return;
      setState(() => _isInitialLoading = false);
    });
    _startNewPostsSync();
  }

  @override
  void dispose() {
    _newPostsPollTimer?.cancel();
    _stopNewPostsRealtimeSubscription();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _startNewPostsSync() {
    if (!AppConfig.isSupabaseConfigured) {
      _newPostsPollTimer = Timer.periodic(
        const Duration(seconds: 12),
        (_) => _checkForNewPosts(),
      );
      return;
    }

    _startNewPostsRealtimeSubscription();
  }

  void _startNewPostsRealtimeSubscription() {
    _stopNewPostsRealtimeSubscription();
    _newPostsRealtimeChannel = Supabase.instance.client
        .channel('home-new-updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'Update',
          callback: (_) => unawaited(_checkForNewPosts()),
        )
        .subscribe((status, [error]) {
      debugPrint(
        '[RT][Home] updates status=$status error=$error',
      );
    });
  }

  void _stopNewPostsRealtimeSubscription() {
    final channel = _newPostsRealtimeChannel;
    if (channel == null) return;
    _newPostsRealtimeChannel = null;
    Supabase.instance.client.removeChannel(channel);
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
    if (!mounted ||
        _activeSection != Sections.forYou ||
        _isCheckingForNewPosts) {
      return;
    }

    final updatesStore = context.read<UpdatesStore>();
    final existingIds = updatesStore.posts.map((post) => post.id).toSet();

    _isCheckingForNewPosts = true;
    try {
      await updatesStore.refreshUpdates();
    } finally {
      _isCheckingForNewPosts = false;
    }

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
    });
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
                        isLoading:
                            edgeStore.isFetching && edgeStore.brief == null,
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
                Consumer2<UpdatesStore, EdgeEngineStore>(
                  builder: (context, store, edgeStore, _) {
                    final enrichedPosts = store.posts
                        .where(
                          (post) => post.project != null && post.admin != null,
                        )
                        .toList();
                    final radarLastSeenAt = _radarSummary?.lastSeenAt;
                    final feedPosts = _showCatchupFilter
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

                    if (_activeSection == Sections.forYou) {
                      if (_isInitialLoading && enrichedPosts.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      if (store.isFetching && store.posts.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
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
                            if (_showCatchupFilter)
                              CatchUpBanner(
                                onClear: () =>
                                    setState(() => _showCatchupFilter = false),
                              ),
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
                ),
                SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
              ],
            ),
          ),
          if (_activeSection == Sections.forYou &&
              _pendingNewPostIds.isNotEmpty)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _jumpToLatest,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_pendingNewPostIds.length} new updates',
                      style: AppTypography.custom(
                        color: AppColors.onAccentForSpace(
                          context.watch<AuthStore>().isInHunterSpace,
                        ),
                        size: 12,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
