part of '../home.dart';

/// Cold-start hydration for the Home tab.
///
/// Order of operations:
/// 1. `initState` paints the cached bootstrap payload synchronously (no
///    spinner on the first frame) via [_applyCachedBootstrapSync].
/// 2. After the first frame, [_hydrateHomeProgressively] fetches a fresh
///    payload and applies it; stores and local state only notify when the
///    content actually changed, so an unchanged feed does not flash.
/// 3. The per-section follow-ups skip anything the payload already
///    delivered (radar, edge brief), which is what keeps the request count
///    down.
mixin _HomeHydration on State<HomeScreen> {
  final UsersApiRepository _usersRepository = UsersApiRepository();

  RadarSummary? _radarSummary;
  bool _isLoadingRadar = true;
  bool _isAcknowledgingRadar = false;
  bool _showCatchupFilter = false;
  bool _isFeedReady = false;
  bool _isEdgeReady = false;
  bool _isBootstrapLoading = false;
  bool _hasAppliedBootstrap = false;

  /// `setState` outside of `initState`, plain assignment inside it.
  void _mutate(VoidCallback change, {bool duringInit = false}) {
    if (duringInit || !mounted) {
      change();
      return;
    }
    setState(change);
  }

  void _applyCachedBootstrapSync() {
    final bootstrap = context.read<HomeBootstrapStore>();
    final cached = bootstrap.cachedFor(context.read<AuthStore>().userId);
    if (cached == null) {
      // Nothing to paint yet: show skeletons from the very first frame
      // instead of flipping into them one frame later.
      _isBootstrapLoading = true;
      return;
    }
    _applyBootstrapPayload(cached, source: 'cache', duringInit: true);
  }

  Future<void> _hydrateHomeProgressively() async {
    if (!mounted) return;
    final bootstrap = context.read<HomeBootstrapStore>();
    final userId = context.read<AuthStore>().userId;
    final updatesStore = context.read<UpdatesStore>();
    final edgeStore = context.read<EdgeEngineStore>();
    final projectsStore = context.read<ProjectsStore>();

    _mutate(() => _isBootstrapLoading = true);

    if (!_hasAppliedBootstrap) {
      await bootstrap.warmUp();
      if (!mounted) return;
      final cached = bootstrap.cachedFor(userId);
      if (cached != null) {
        _applyBootstrapPayload(cached, source: 'cache');
      }
    }

    final remote = await bootstrap.fetchRemote(
      userId: userId,
      feedLimit: 100,
      windowDays: 7,
    );
    if (!mounted) return;
    if (remote != null) {
      _applyBootstrapPayload(remote, source: 'network');
    }

    try {
      await Future.wait<void>([
        projectsStore.fetchProjectsOnce(),
        remote != null && remote.hasFeed
            ? updatesStore.refreshUpdates()
            : updatesStore.fetchUpdatesOnce(),
        remote != null && remote.hasEdgeBrief
            ? edgeStore.ensureFeed()
            : edgeStore.fetchOnce(),
        if (remote == null || !remote.hasRadar) _loadRadar(),
      ]);
    } finally {
      if (mounted) {
        final feedReady = updatesStore.posts.isNotEmpty;
        final edgeReady = edgeStore.brief != null;
        _mutate(() {
          _isBootstrapLoading = false;
          _isFeedReady = feedReady;
          _isEdgeReady = edgeReady;
        });
        if (feedReady) {
          StartupMetricsService.markHomeFeedReady(source: 'network');
        }
        if (edgeReady) {
          StartupMetricsService.markEdgeReady(source: 'network');
        }
      }
    }
  }

  void _applyBootstrapPayload(
    HomeBootstrapPayload payload, {
    required String source,
    bool duringInit = false,
  }) {
    final updatesStore = context.read<UpdatesStore>();
    final edgeStore = context.read<EdgeEngineStore>();
    final projectsStore = context.read<ProjectsStore>();
    final notify = !duringInit;

    unawaited(
      projectsStore.hydrateFollowStateFromMeSummary(
        payload.meSummary,
        notify: false,
      ),
    );
    updatesStore.hydrateFromUpdates(payload.feedItems, notify: notify);
    edgeStore.hydrateBrief(payload.edgeBrief, notify: notify);
    context.read<HomeBootstrapStore>().markApplied(payload);
    _hasAppliedBootstrap = true;

    final radar = payload.radar;
    final current = _radarSummary;
    final radarChanged =
        radar != null && (current == null || !current.contentEquals(radar));
    final feedReady = _isFeedReady || payload.hasFeed;
    final edgeReady = _isEdgeReady || payload.hasEdgeBrief;
    final loadingRadar = radar == null && current == null;

    if (radarChanged ||
        feedReady != _isFeedReady ||
        edgeReady != _isEdgeReady ||
        loadingRadar != _isLoadingRadar) {
      _mutate(
        () {
          if (radarChanged) _radarSummary = radar;
          _isFeedReady = feedReady;
          _isEdgeReady = edgeReady;
          _isLoadingRadar = loadingRadar;
        },
        duringInit: duringInit,
      );
    }

    if (feedReady) StartupMetricsService.markHomeFeedReady(source: source);
    if (edgeReady) StartupMetricsService.markEdgeReady(source: source);
  }

  Future<void> _loadRadar() async {
    if (!mounted) return;
    // Only drop into the skeleton when there is nothing to show yet.
    if (_radarSummary == null && !_isLoadingRadar) {
      _mutate(() => _isLoadingRadar = true);
    }

    RadarSummary? radar;
    try {
      radar = await _usersRepository.fetchRadar();
    } catch (_) {
      radar = null;
    }
    if (!mounted) return;

    final current = _radarSummary;
    final changed = radar == null
        ? current != null
        : current == null || !current.contentEquals(radar);
    _mutate(() {
      if (changed) _radarSummary = radar;
      _isLoadingRadar = false;
    });
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
      final now = DateTime.now();
      setState(() {
        _radarSummary = RadarSummary(
          asOf: now,
          lastSeenAt: now,
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

  /// Pull-to-refresh: every section, radar included.
  Future<void> _refreshAllSections() async {
    final projectsStore = context.read<ProjectsStore>();
    final updatesStore = context.read<UpdatesStore>();
    final edgeStore = context.read<EdgeEngineStore>();
    await Future.wait<void>([
      projectsStore.refreshProjects(),
      updatesStore.refreshUpdates(),
      edgeStore.refresh(),
      _loadRadar(),
    ]);

    if (!mounted) return;
    setState(() {
      _showCatchupFilter = false;
      _isFeedReady = updatesStore.posts.isNotEmpty;
      _isEdgeReady = edgeStore.brief != null;
    });
  }
}
