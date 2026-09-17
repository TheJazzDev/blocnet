import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/gems/domain/gem_keeper.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/gems/presentation/gem_action_handlers.dart';
import 'package:blocnet/features/gems/presentation/pages/gem_page_sources.dart';
import 'package:blocnet/features/gems/presentation/widgets/gem_page/gem_page_bar.dart';
import 'package:blocnet/features/gems/presentation/widgets/gem_page/gem_page_body.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_notice.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_scroll_view.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/follow_preference_bottom_sheet.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/detail_dialogs.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/share_link.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A gem, as a member sees it: what it is, who keeps it and how reliably,
/// its updates as a timeline, Follow and Share.
class GemPage extends StatefulWidget {
  const GemPage({
    super.key,
    required this.projectId,
    this.sources,
    this.clock,
  });

  final String projectId;
  final GemPageSources? sources;
  final DateTime Function()? clock;

  @override
  State<GemPage> createState() => _GemPageState();
}

class _GemPageState extends State<GemPage> {
  late final GemPageSources _sources = widget.sources ?? GemPageSources();
  Project? _fetched;
  bool _projectFailed = false;
  List<Update>? _updates;
  bool _updatesFailed = false;
  HunterReliability? _keeper;

  String get _id => widget.projectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() => Future.wait([_loadProject(), _loadUpdates()]);

  Future<void> _loadProject() async {
    try {
      final project = await _sources.project(_id);
      if (!mounted) return;
      setState(() {
        _fetched = project;
        _projectFailed = project == null;
      });
    } catch (_) {
      if (mounted) setState(() => _projectFailed = true);
    }
    if (!mounted) return;
    final project = _fetched ?? _storeProject();
    final keeperId = project?.ownerReliability?.profileId ?? project?.adminId;
    if (keeperId != null && keeperId.isNotEmpty) await _loadKeeper(keeperId);
  }

  Future<void> _loadKeeper(String profileId) async {
    try {
      final keeper = await _sources.keeper(profileId);
      if (mounted) setState(() => _keeper = keeper);
    } catch (_) {
      // The card keeps the summary the project read carried.
    }
  }

  Future<void> _loadUpdates() async {
    if (mounted && _updatesFailed) setState(() => _updatesFailed = false);
    try {
      final updates = await _sources.updates(_id);
      if (mounted) setState(() => _updates = updates);
    } catch (_) {
      if (mounted) setState(() => _updatesFailed = true);
    }
  }

  Project? _storeProject() => _fromStores(
        context.read<ProjectsStore>(),
        context.read<UpdatesStore>().updates,
      );

  /// The store's copy, else the copy nested in one of the gem's updates.
  Project? _fromStores(ProjectsStore store, Iterable<Update> updates) {
    final fromStore = store.getProjectById(_id);
    if (fromStore != null) return fromStore;
    for (final u in updates) {
      if (u.projectId == _id && u.project != null) return u.project;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectsStore>();
    final storeUpdates = context
        .watch<UpdatesStore>()
        .updates
        .where((u) => u.projectId == _id)
        .toList();
    final project = _merge(_fromStores(store, storeUpdates), _fetched);
    final title = project?.name ?? 'Gem';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            GemPageBar(
              title: title,
              onBack: () => Navigator.of(context).maybePop(),
              onShare: project == null
                  ? null
                  : () => shareBlocnetLink(
                        context,
                        title: project.name,
                        deepPath: '/projects/${project.id}',
                      ),
            ),
            Expanded(
              child: project == null
                  ? _missing()
                  : _body(project, store, storeUpdates),
            ),
          ],
        ),
      ),
    );
  }

  Widget _missing() {
    return GemsScrollView(
      onRefresh: _load,
      children: [
        if (_projectFailed)
          GemsNotice(
            icon: Icons.cloud_off_rounded,
            title: "Couldn't load this gem",
            actionLabel: 'Try again',
            onAction: () {
              setState(() => _projectFailed = false);
              _loadProject();
            },
          )
        else
          const GemsLoading(),
      ],
    );
  }

  Widget _body(Project project, ProjectsStore store, List<Update> fromStore) {
    final now = (widget.clock ?? DateTime.now)();
    final updates = [...(_updates ?? fromStore)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final gem = GemListings.build(
      projects: [project],
      updates: updates,
      now: now,
      hunters: {if (_keeper != null) _keeper!.profileId: _keeper!},
    ).single;

    return GemPageBody(
      gem: gem,
      updates: updates,
      updatesState: _updates != null
          ? GemsLoadState.ready
          : _updatesFailed
              ? GemsLoadState.error
              : GemsLoadState.loading,
      isFollowed: store.isProjectFollowed(project.id),
      now: now,
      callbacks: GemPageCallbacks(
        onToggleFollow: () => store.toggleFollowProject(project.id),
        onPreferences: () => showFollowPreferenceBottomSheet(
          context,
          projectId: project.id,
          projectName: project.name,
        ),
        onOpenKeeper: (GemKeeper k) => openKeeperProfile(context, k),
        onAsk: () => askForUpdate(context, store, project.id, project.name),
        onOpenUpdate: (u) => showUpdateDetailsDialog(context, u.id),
        onRetryUpdates: _loadUpdates,
        onRefresh: _load,
      ),
    );
  }

  /// The store's copy carries live follower counts; the fetched copy carries
  /// reliability and the last update time.
  Project? _merge(Project? live, Project? fetched) {
    if (fetched == null) return live;
    if (live == null) return fetched;
    return Project(
      id: fetched.id,
      logo: fetched.logo,
      name: fetched.name,
      details: fetched.details,
      adminId: fetched.adminId,
      admin: fetched.admin ?? live.admin,
      website: fetched.website,
      createdAt: fetched.createdAt,
      primaryTagId: fetched.primaryTagId,
      primaryTag: fetched.primaryTag,
      description: fetched.description,
      followersCount: live.followersCount,
      status: fetched.status,
      secondaryTagIds: fetched.secondaryTagIds,
      secondaryTags: fetched.secondaryTags,
      apps: fetched.apps,
      socials: fetched.socials,
      updatesCount: fetched.updatesCount ?? live.updatesCount,
      ownerReliability: fetched.ownerReliability ?? live.ownerReliability,
      lastUpdateAt: fetched.lastUpdateAt ?? live.lastUpdateAt,
    );
  }
}
