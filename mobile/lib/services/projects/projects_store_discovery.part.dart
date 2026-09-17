part of 'projects_store.dart';

mixin _ProjectsStoreDiscoveryMixin on ChangeNotifier {
  List<Project> get _projects;
  Set<String> get _followedProjectIds;

  /// A popularity proxy (followers and loaded updates), never shown. Only
  /// Home's day-one "Moving right now" ordering still uses it; Gems sorts by
  /// real numbers instead (`GemsOrdering`).
  double hypeScoreForProject(
    Project project, {
    int? updatesCountOverride,
  }) {
    final followers = project.followersCount;
    final updatesCount = updatesCountOverride ?? (project.posts?.length ?? 0);
    final raw = (followers * 0.05 + updatesCount * 0.3).clamp(0.0, 10.0);
    return double.parse(raw.toStringAsFixed(1));
  }

  bool isProjectFollowed(String projectId) =>
      _followedProjectIds.contains(projectId);

  Set<String> manageableProjectIds({
    required String userId,
    required Iterable<Update> updates,
  }) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return const <String>{};

    final ownedIds = _projects
        .where((project) => project.adminId == normalizedUserId)
        .map((project) => project.id)
        .toSet();
    final contributedIds = updates
        .where((update) => update.adminId == normalizedUserId)
        .map((update) => update.projectId)
        .toSet();

    return <String>{...ownedIds, ...contributedIds};
  }

  bool isProjectManageable({
    required String projectId,
    required String userId,
    required Iterable<Update> updates,
  }) {
    return manageableProjectIds(
      userId: userId,
      updates: updates,
    ).contains(projectId);
  }
}
