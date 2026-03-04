part of 'projects_store.dart';

mixin _ProjectsStoreDiscoveryMixin on ChangeNotifier {
  Set<Priority> get _discoverPriorityFilters;
  Set<String> get _discoverPrimaryTagFilters;
  Set<String> get _discoverSecondaryTagFilters;
  List<Project> get _projects;
  Set<String> get _followedProjectIds;

  List<Project> discoverProjects({
    required Iterable<Update> updates,
  }) {
    final updateCountsByProject = <String, int>{};
    final priorityLabelsByProject = <String, Set<String>>{};
    for (final update in updates) {
      updateCountsByProject.update(
        update.projectId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      priorityLabelsByProject
          .putIfAbsent(update.projectId, () => <String>{})
          .add(update.priority.label.trim().toLowerCase());
    }

    final selectedPriorityLabels = _discoverPriorityFilters
        .map((priority) => priority.label.trim().toLowerCase())
        .toSet();

    final filtered = _projects.where((project) {
      if (_discoverPrimaryTagFilters.isNotEmpty &&
          !_discoverPrimaryTagFilters.contains(project.primaryTag.name)) {
        return false;
      }

      if (_discoverSecondaryTagFilters.isNotEmpty) {
        final projectSecondaryNames = project.secondaryTags
            .map((tag) => tag.name.trim())
            .where((name) => name.isNotEmpty)
            .toSet();
        final hasSecondaryMatch = projectSecondaryNames.any(
          _discoverSecondaryTagFilters.contains,
        );
        if (!hasSecondaryMatch) {
          return false;
        }
      }

      if (selectedPriorityLabels.isNotEmpty) {
        final projectLabels = priorityLabelsByProject[project.id] ?? <String>{};
        if (!projectLabels.any(selectedPriorityLabels.contains)) {
          return false;
        }
      }

      return true;
    }).toList(growable: false);

    filtered.sort((left, right) {
      final leftScore = hypeScoreForProject(
        left,
        updatesCountOverride: updateCountsByProject[left.id],
      );
      final rightScore = hypeScoreForProject(
        right,
        updatesCountOverride: updateCountsByProject[right.id],
      );
      final scoreCompare = rightScore.compareTo(leftScore);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return right.createdAt.compareTo(left.createdAt);
    });

    return filtered;
  }

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

  List<Project> followedAndManagedProjects({
    required String userId,
    required Iterable<Update> updates,
  }) {
    final manageableIds = manageableProjectIds(
      userId: userId,
      updates: updates,
    );
    final mergedIds = <String>{..._followedProjectIds, ...manageableIds};

    final result = _projects
        .where((project) => mergedIds.contains(project.id))
        .toList(growable: false);
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }
}
