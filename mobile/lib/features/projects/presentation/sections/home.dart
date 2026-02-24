import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/engagement/data/models/edge_brief_model.dart';
import 'package:blocnet/features/engagement/data/models/edge_explain_model.dart';
import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:blocnet/features/projects/presentation/sections/explore/explore.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/top_hunters_row.dart';
import 'package:blocnet/services/edge_engine_store.dart';
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
      builder: (_) => _EdgeExplainSheet(explain: explain),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 96;
    final edgeStore = context.watch<EdgeEngineStore>();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary500,
            backgroundColor: AppColors.bgSurface,
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FeedTabDelegate(
                    activeSection: _activeSection,
                    onTabChanged: _onTabChanged,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _AlphaRadarCard(
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
                      child: _EdgeBriefCard(
                        brief: edgeStore.brief,
                        isLoading:
                            edgeStore.isFetching && edgeStore.brief == null,
                        onAction: _sendEdgeFeedback,
                        onExplain: _openEdgeExplain,
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
                    final rankedFeedPosts = [...feedPosts]
                      ..sort((a, b) {
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
                          sliver: SliverToBoxAdapter(child: _EmptyFeed()),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (_showCatchupFilter)
                              _CatchUpBanner(
                                onClear: () =>
                                    setState(() => _showCatchupFilter = false),
                              ),
                            ...rankedFeedPosts
                                .map((post) => FeedCard(post: post)),
                          ]),
                        ),
                      );
                    }

                    return SliverToBoxAdapter(
                      child: ExploreSection(allPosts: store.posts),
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
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_pendingNewPostIds.length} new updates',
                      style: AppTypography.custom(
                        color: Colors.black,
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

// ─────────────────────────────────────────────────────────────────────────────
// Feed tab bar: Updates · General (underline style)
// ─────────────────────────────────────────────────────────────────────────────

class _FeedTabDelegate extends SliverPersistentHeaderDelegate {
  const _FeedTabDelegate({
    required this.activeSection,
    required this.onTabChanged,
  });

  final Section activeSection;
  final ValueChanged<Section> onTabChanged;

  static const double _height = 44.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_FeedTabDelegate oldDelegate) =>
      oldDelegate.activeSection != activeSection;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _FeedTabBar(
      activeSection: activeSection,
      onTabChanged: onTabChanged,
    );
  }
}

class _FeedTabBar extends StatelessWidget {
  const _FeedTabBar({
    required this.activeSection,
    required this.onTabChanged,
  });

  final Section activeSection;
  final ValueChanged<Section> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Updates',
            isActive: activeSection == Sections.forYou,
            onTap: () => onTabChanged(Sections.forYou),
          ),
          _Tab(
            label: 'General',
            isActive: activeSection == Sections.explore,
            onTap: () => onTabChanged(Sections.explore),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.teal400 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        height: 44,
        child: Text(
          label,
          style: AppTypography.custom(
            color: isActive ? AppColors.teal400 : AppColors.textFaint,
            size: 13,
            weight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AlphaRadarCard extends StatelessWidget {
  const _AlphaRadarCard({
    required this.radar,
    required this.isLoading,
    required this.onCatchUp,
  });

  final RadarSummary? radar;
  final bool isLoading;
  final VoidCallback onCatchUp;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary400,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading alpha radar...',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    final summary = radar;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    final subtitle = summary.hasUpdates
        ? '${summary.newUpdatesCount} new updates · ${summary.highUrgencyCount} high urgency'
        : 'You are fully caught up';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_rounded, size: 16, color: AppColors.primary400),
              const SizedBox(width: 8),
              Text(
                'ALPHA RADAR',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10,
                  weight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (summary.hasUpdates)
                TextButton(
                  onPressed: onCatchUp,
                  child: Text(
                    'Catch up now',
                    style: AppTypography.custom(
                      color: AppColors.primary400,
                      size: 12,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            subtitle,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 14,
              weight: FontWeight.w500,
            ),
          ),
          if (summary.activeProjects.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.activeProjects.take(3).map((project) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    '${project.projectName} · ${project.newCount}',
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 10,
                      weight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _EdgeBriefCard extends StatelessWidget {
  const _EdgeBriefCard({
    required this.brief,
    required this.isLoading,
    required this.onAction,
    required this.onExplain,
  });

  final EdgeBriefResponse? brief;
  final bool isLoading;
  final Future<void> Function(EdgeBriefDecision decision, String action)
      onAction;
  final Future<void> Function(EdgeBriefDecision decision) onExplain;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgSurface,
              AppColors.bgSurface.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderSubtle.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary400,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading edge brief...',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 13,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final summary = brief;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary500.withValues(alpha: 0.2),
                      AppColors.primary500.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: AppColors.primary400,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'BLOCNET EDGE ENGINE',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10,
                  weight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary.headline.trim().isEmpty
                ? 'Edge intelligence is ready.'
                : summary.headline,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 14,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BriefMetricChip(
                label: '${summary.totalSignals} signals',
              ),
              _BriefMetricChip(
                label: '${summary.recommendedNowCount} act now',
              ),
              _BriefMetricChip(
                label: '${summary.watchCount} watch',
              ),
            ],
          ),
          if (summary.topDecisions.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...summary.topDecisions.take(3).map((decision) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EdgeDecisionRow(
                  decision: decision,
                  onAction: onAction,
                  onExplain: onExplain,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _BriefMetricChip extends StatelessWidget {
  const _BriefMetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary500.withValues(alpha: 0.15),
            AppColors.primary500.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.custom(
          color: AppColors.primary400,
          size: 11,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EdgeDecisionRow extends StatelessWidget {
  const _EdgeDecisionRow({
    required this.decision,
    required this.onAction,
    required this.onExplain,
  });

  final EdgeBriefDecision decision;
  final Future<void> Function(EdgeBriefDecision decision, String action)
      onAction;
  final Future<void> Function(EdgeBriefDecision decision) onExplain;

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _urgencyColor(decision.urgency);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgElevated,
            AppColors.bgElevated.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgencyColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            decision.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 13,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      urgencyColor.withValues(alpha: 0.2),
                      urgencyColor.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: urgencyColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  decision.urgency.toUpperCase(),
                  style: AppTypography.custom(
                    color: urgencyColor,
                    size: 9,
                    weight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${decision.projectName} · ${decision.edgeScore.toStringAsFixed(2)}',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 11,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionChip(
                label: 'Act',
                action: 'act',
                recommendedAction: decision.recommendedAction,
                onTap: () => onAction(decision, 'act'),
              ),
              const SizedBox(width: 6),
              _ActionChip(
                label: 'Watch',
                action: 'watch',
                recommendedAction: decision.recommendedAction,
                onTap: () => onAction(decision, 'watch'),
              ),
              const SizedBox(width: 6),
              _ActionChip(
                label: 'Ignore',
                action: 'ignore',
                recommendedAction: decision.recommendedAction,
                onTap: () => onAction(decision, 'ignore'),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => onExplain(decision),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Why?',
                    style: AppTypography.custom(
                      color: AppColors.primary400,
                      size: 10,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _urgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return AppColors.error500;
      case 'medium':
        return AppColors.warning500;
      default:
        return AppColors.primary400;
    }
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.action,
    required this.recommendedAction,
    required this.onTap,
  });

  final String label;
  final String action;
  final String recommendedAction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRecommended = action == recommendedAction;
    final color = _actionColor(action);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isRecommended
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.15),
                  ],
                )
              : null,
          color: isRecommended ? null : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: isRecommended ? 0.4 : 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.custom(
            color: color,
            size: 11,
            weight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Color _actionColor(String value) {
    switch (value) {
      case 'act':
        return AppColors.successColor;
      case 'watch':
        return AppColors.warning500;
      case 'ignore':
      default:
        return AppColors.textMuted;
    }
  }
}

class _EdgeExplainSheet extends StatelessWidget {
  const _EdgeExplainSheet({required this.explain});

  final EdgeExplainResponse explain;

  @override
  Widget build(BuildContext context) {
    final update = explain.update!;
    final details = explain.explanation!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Why BEE ranked this',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 16,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                update.title,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: 13,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${update.projectName} · ${update.urgency.toUpperCase()}',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 11,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  details.narrative.trim().isEmpty
                      ? details.explanationPreview
                      : details.narrative,
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: 12,
                    weight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: details.reasonCodes.map((reason) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      reason,
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 10,
                        weight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _ExplainMetricRow(label: 'Edge score', value: details.edgeScore),
              _ExplainMetricRow(
                  label: 'Urgency component', value: details.components.urgency),
              _ExplainMetricRow(
                  label: 'Recency component', value: details.components.recency),
              _ExplainMetricRow(
                  label: 'Relevance component',
                  value: details.components.relevance),
              _ExplainMetricRow(
                  label: 'Novelty component', value: details.components.novelty),
              _ExplainMetricRow(
                  label: 'Penalty component',
                  value: details.components.penalties),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplainMetricRow extends StatelessWidget {
  const _ExplainMetricRow({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 11,
                weight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value.toStringAsFixed(3),
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 11,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatchUpBanner extends StatelessWidget {
  const _CatchUpBanner({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined,
              size: 14, color: AppColors.primary400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Catch-up filter: unseen or high urgency',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 11,
                weight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Clear',
              style: AppTypography.custom(
                color: AppColors.primary400,
                size: 11,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty feed state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(
            Icons.article_outlined,
            size: 36,
            color: AppColors.textFaint,
          ),
          const SizedBox(height: 10),
          Text(
            'No updates yet',
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: 15,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hunter intel will appear here when updates are posted.',
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 12,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
