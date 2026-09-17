import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/gems/domain/gems_ordering.dart';
import 'package:blocnet/features/gems/domain/gems_tab.dart';
import 'package:blocnet/features/gems/presentation/gem_action_handlers.dart';
import 'package:blocnet/features/gems/presentation/gems_navigation.dart';
import 'package:blocnet/features/gems/presentation/widgets/board/board_view.dart';
import 'package:blocnet/features/gems/presentation/widgets/discover/discover_view.dart';
import 'package:blocnet/features/gems/presentation/widgets/gems_tab_bar.dart';
import 'package:blocnet/features/gems/presentation/widgets/hunters/hunters_view.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_scroll_view.dart';
import 'package:blocnet/services/gems/hunter_leaderboard_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Gems bottom tab: Discover · Your board · Hunters.
///
/// Other code opens it on a view with `GemsNavigation.open`.
class GemsScreen extends StatefulWidget {
  const GemsScreen({
    super.key,
    this.initialTab = GemsTab.discover,
    this.leaderboard,
    this.clock,
  });

  final GemsTab initialTab;

  /// Injectable for tests; the screen owns one otherwise.
  final HunterLeaderboardStore? leaderboard;
  final DateTime Function()? clock;

  @override
  State<GemsScreen> createState() => _GemsScreenState();
}

class _GemsScreenState extends State<GemsScreen> {
  late GemsTab _tab;
  late final HunterLeaderboardStore _leaderboard;
  GemSort _sort = GemSort.mostActive;
  String? _tag;

  /// True until the first project and update reads have returned.
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _tab = GemsNavigation.requests.take() ?? widget.initialTab;
    _leaderboard = widget.leaderboard ?? HunterLeaderboardStore();
    GemsNavigation.requests.addListener(_onRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    GemsNavigation.requests.removeListener(_onRequest);
    if (widget.leaderboard == null) _leaderboard.dispose();
    super.dispose();
  }

  void _onRequest() {
    final tab = GemsNavigation.requests.take();
    if (tab == null || !mounted) return;
    setState(() => _tab = tab);
  }

  Future<void> _boot() async {
    if (!mounted) return;
    final projects = context.read<ProjectsStore>();
    final updates = context.read<UpdatesStore>();
    await Future.wait([
      projects.fetchProjectsOnce(),
      updates.fetchUpdatesOnce(),
      _leaderboard.loadOnce(),
    ]);
    if (mounted) setState(() => _booting = false);
  }

  Future<void> _refreshGems() async {
    await Future.wait([
      context.read<ProjectsStore>().refreshProjects(),
      context.read<UpdatesStore>().refreshUpdates(),
      _leaderboard.refresh(),
    ]);
  }

  GemsLoadState _gemsState(ProjectsStore projects, UpdatesStore updates) {
    if (_booting || projects.isFetching || updates.isFetching) {
      return projects.projects.isEmpty
          ? GemsLoadState.loading
          : GemsLoadState.ready;
    }
    if (projects.projects.isEmpty && projects.lastError != null) {
      return GemsLoadState.error;
    }
    return GemsLoadState.ready;
  }

  GemsLoadState _huntersState() {
    if (_leaderboard.error != null && _leaderboard.entries.isEmpty) {
      return _leaderboard.isLoading
          ? GemsLoadState.loading
          : GemsLoadState.error;
    }
    if (!_leaderboard.hasLoaded) return GemsLoadState.loading;
    return GemsLoadState.ready;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HunterLeaderboardStore>.value(
      value: _leaderboard,
      child: Scaffold(
        backgroundColor: AppColors.bgBase,
        body: Column(
          children: [
            GemsTabBar(
              active: _tab,
              onSelect: (tab) => setState(() => _tab = tab),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    return Consumer3<ProjectsStore, UpdatesStore, HunterLeaderboardStore>(
      builder: (context, projects, updates, leaderboard, _) {
        final now = (widget.clock ?? DateTime.now)();
        final actions = liveGemActions(context, projects);
        final state = _gemsState(projects, updates);
        final followed = projects.followedProjectIds;

        switch (_tab) {
          case GemsTab.discover:
            return DiscoverView(
              state: state,
              gems: GemListings.build(
                projects: projects.projects,
                updates: updates.updates,
                hunters: leaderboard.byProfileId,
                now: now,
              ),
              sort: _sort,
              tag: _tag,
              now: now,
              actions: actions,
              onSort: (sort) => setState(() => _sort = sort),
              onSelectTag: (tag) => setState(() => _tag = tag),
              onRefresh: _refreshGems,
            );
          case GemsTab.board:
            return BoardView(
              state: state,
              gems: GemListings.build(
                projects: projects.projects,
                updates: updates.updates,
                hunters: leaderboard.byProfileId,
                now: now,
                onlyIds: followed,
              ),
              now: now,
              actions: actions,
              onDiscover: () => setState(() => _tab = GemsTab.discover),
              onRefresh: _refreshGems,
            );
          case GemsTab.hunters:
            return HuntersView(
              state: _huntersState(),
              entries: leaderboard.entries,
              yourHunterIds: _yourHunterIds(projects),
              hasMore: leaderboard.hasMore,
              isLoadingMore: leaderboard.isLoadingMore,
              onOpen: (keeper) => openKeeperProfile(context, keeper),
              onLoadMore: leaderboard.loadMore,
              onRefresh: leaderboard.refresh,
            );
        }
      },
    );
  }

  /// Keepers of the gems the member follows.
  Set<String> _yourHunterIds(ProjectsStore projects) {
    final followed = projects.followedProjectIds;
    return {
      for (final p in projects.projects)
        if (followed.contains(p.id) && p.ownerReliability != null)
          p.ownerReliability!.profileId,
    };
  }
}
