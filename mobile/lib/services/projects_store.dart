import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/data/models/follow_preference_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/repositories/updates_api_repository.dart';
import 'package:blocnet/features/projects/data/repositories/projects_api_repository.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:flutter/material.dart';

class ProjectsStore extends ChangeNotifier {
  ProjectsStore({
    ProjectsApiRepository? projectsRepository,
    UpdatesApiRepository? postsRepository,
    UsersApiRepository? usersRepository,
  })  : _projectsRepository = projectsRepository ?? ProjectsApiRepository(),
        _postsRepository = postsRepository ?? UpdatesApiRepository(),
        _usersRepository = usersRepository ?? UsersApiRepository();

  final ProjectsApiRepository _projectsRepository;
  final UpdatesApiRepository _postsRepository;
  final UsersApiRepository _usersRepository;

  final List<Project> _projects = [];
  final Set<String> _followedProjectIds = <String>{};
  final Map<String, FollowPreference> _followPreferences =
      <String, FollowPreference>{};
  final Set<String> _discoverPrimaryTagFilters = <String>{};
  final Set<String> _discoverSecondaryTagFilters = <String>{};
  final Set<Priority> _discoverPriorityFilters = <Priority>{};
  bool _isFetching = false;
  bool _isTogglingFollow = false;
  bool _isUpdatingFollowPreferences = false;
  String? _lastError;

  List<Project> get projects => List.unmodifiable(_projects);
  Set<String> get followedProjectIds => Set.unmodifiable(_followedProjectIds);
  Map<String, FollowPreference> get followPreferences =>
      Map.unmodifiable(_followPreferences);
  Set<String> get discoverPrimaryTagFilters =>
      Set.unmodifiable(_discoverPrimaryTagFilters);
  Set<String> get discoverSecondaryTagFilters =>
      Set.unmodifiable(_discoverSecondaryTagFilters);
  Set<Priority> get discoverPriorityFilters =>
      Set.unmodifiable(_discoverPriorityFilters);
  bool get hasDiscoverFilters =>
      _discoverPrimaryTagFilters.isNotEmpty ||
      _discoverSecondaryTagFilters.isNotEmpty ||
      _discoverPriorityFilters.isNotEmpty;
  bool get isFetching => _isFetching;
  bool get isTogglingFollow => _isTogglingFollow;
  bool get isUpdatingFollowPreferences => _isUpdatingFollowPreferences;
  String? get lastError => _lastError;

  Future<void> fetchProjectsOnce() async {
    if (_projects.isNotEmpty || _isFetching) return;
    await refreshProjects();
  }

  Future<void> refreshProjects() async {
    if (_isFetching) return;

    _isFetching = true;
    notifyListeners();

    try {
      final projects = await _projectsRepository.fetchProjects(limit: 500);
      final posts = await _postsRepository.fetchPosts(limit: 500);

      final postsByProject = <String, List<Update>>{};
      for (final post in posts) {
        postsByProject.putIfAbsent(post.projectId, () => []).add(post);
      }

      _projects
        ..clear()
        ..addAll(
          projects.map((project) {
            final admin = project.admin ?? _fallbackAdmin(project.adminId);
            final relatedPosts = postsByProject[project.id] ?? const <Update>[];

            return project.copyWith(
              posts: relatedPosts,
              admin: admin,
            );
          }),
        );

      try {
        final me = await _usersRepository.fetchMe();
        final followedIds =
            (me?['followedProjectIds'] as List<dynamic>? ?? const [])
                .map((value) => value.toString())
                .toSet();
        final parsedPreferences = _usersRepository.parseFollowPreferencesFromMe(
          me,
        );

        _followedProjectIds
          ..clear()
          ..addAll(followedIds);
        _followPreferences
          ..clear()
          ..addAll(parsedPreferences);
        for (final projectId in _followedProjectIds) {
          _followPreferences.putIfAbsent(
            projectId,
            () => const FollowPreference(
              alertLevel: FollowAlertLevel.all,
              mutedUntil: null,
            ),
          );
        }
      } catch (_) {
        // Ignore profile sync failures and keep local follow cache.
      }

      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
      debugPrint('Failed to fetch projects from API: $error');
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  void addProject(Project project) {
    _projects.add(project);
    notifyListeners();
  }

  void removeProject(String projectId) {
    _projects.removeWhere((project) => project.id == projectId);
    notifyListeners();
  }

  void updateProject(Project updatedProject) {
    final index =
        _projects.indexWhere((project) => project.id == updatedProject.id);
    if (index != -1) {
      _projects[index] = updatedProject;
      notifyListeners();
    }
  }

  Project? getProjectById(String projectId) {
    for (final project in _projects) {
      if (project.id == projectId) {
        return project;
      }
    }
    return null;
  }

  void setDiscoverFilters({
    required Set<String> primaryTags,
    required Set<String> secondaryTags,
    required Set<Priority> priorities,
  }) {
    _discoverPrimaryTagFilters
      ..clear()
      ..addAll(primaryTags);
    _discoverSecondaryTagFilters
      ..clear()
      ..addAll(secondaryTags);
    _discoverPriorityFilters
      ..clear()
      ..addAll(priorities);
    notifyListeners();
  }

  void clearDiscoverFilters() {
    if (!hasDiscoverFilters) return;
    _discoverPrimaryTagFilters.clear();
    _discoverSecondaryTagFilters.clear();
    _discoverPriorityFilters.clear();
    notifyListeners();
  }

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

  Future<void> toggleFollowProject(String projectId) async {
    if (_isTogglingFollow) return;

    final shouldFollow = !_followedProjectIds.contains(projectId);
    _isTogglingFollow = true;
    _lastError = null;
    notifyListeners();

    if (shouldFollow) {
      _followedProjectIds.add(projectId);
      _followPreferences.putIfAbsent(
        projectId,
        () => const FollowPreference(
          alertLevel: FollowAlertLevel.all,
          mutedUntil: null,
        ),
      );
      _updateProjectFollowerCount(projectId, 1);
    } else {
      _followedProjectIds.remove(projectId);
      _followPreferences.remove(projectId);
      _updateProjectFollowerCount(projectId, -1);
    }
    notifyListeners();

    try {
      if (shouldFollow) {
        await _projectsRepository.followProject(projectId);
      } else {
        await _projectsRepository.unfollowProject(projectId);
      }
    } catch (error) {
      if (shouldFollow) {
        _followedProjectIds.remove(projectId);
        _followPreferences.remove(projectId);
        _updateProjectFollowerCount(projectId, -1);
      } else {
        _followedProjectIds.add(projectId);
        _followPreferences.putIfAbsent(
          projectId,
          () => const FollowPreference(
            alertLevel: FollowAlertLevel.all,
            mutedUntil: null,
          ),
        );
        _updateProjectFollowerCount(projectId, 1);
      }
      _lastError = error.toString();
    } finally {
      _isTogglingFollow = false;
      notifyListeners();
    }
  }

  FollowPreference preferenceForProject(String projectId) {
    return _followPreferences[projectId] ??
        const FollowPreference(
          alertLevel: FollowAlertLevel.all,
          mutedUntil: null,
        );
  }

  Future<void> updateFollowPreferences(
    String projectId, {
    FollowAlertLevel? alertLevel,
    DateTime? mutedUntil,
    bool clearMute = false,
  }) async {
    if (_isUpdatingFollowPreferences) return;

    final previous = _followPreferences[projectId] ??
        const FollowPreference(
          alertLevel: FollowAlertLevel.all,
          mutedUntil: null,
        );

    final optimistic = previous.copyWith(
      alertLevel: alertLevel,
      mutedUntil: mutedUntil,
      clearMute: clearMute,
    );

    _isUpdatingFollowPreferences = true;
    _lastError = null;
    _followPreferences[projectId] = optimistic;
    notifyListeners();

    try {
      final response = await _projectsRepository.updateFollowPreferences(
        projectId,
        alertMinUrgency: alertLevel?.wireValue,
        mutedUntil: mutedUntil,
        clearMute: clearMute,
      );

      if (response != null) {
        _followPreferences[projectId] = FollowPreference.fromApi(response);
      }
    } catch (error) {
      _lastError = error.toString();
      _followPreferences[projectId] = previous;
    } finally {
      _isUpdatingFollowPreferences = false;
      notifyListeners();
    }
  }

  Admin _fallbackAdmin(String adminId) {
    return Admin(
      id: adminId,
      name: 'Admin',
      username: adminId.isEmpty
          ? '@admin'
          : '@${adminId.substring(0, adminId.length >= 6 ? 6 : adminId.length)}',
      imageUrl: '',
      followers: 0,
    );
  }

  void _updateProjectFollowerCount(String projectId, int delta) {
    final index = _projects.indexWhere((project) => project.id == projectId);
    if (index == -1) return;

    final current = _projects[index];
    final nextFollowers = (current.followersCount + delta).clamp(0, 1 << 31);
    _projects[index] = current.copyWith(followersCount: nextFollowers);
  }
}
