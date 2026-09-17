part of 'projects_store.dart';

mixin _ProjectsStoreDiscoveryMixin on ChangeNotifier {
  List<Project> get _projects;
  Set<String> get _followedProjectIds;

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
