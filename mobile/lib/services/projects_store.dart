import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/repositories/posts_api_repository.dart';
import 'package:blocnet/features/projects/data/repositories/projects_api_repository.dart';
import 'package:flutter/material.dart';

class ProjectsStore extends ChangeNotifier {
  ProjectsStore({
    ProjectsApiRepository? projectsRepository,
    PostsApiRepository? postsRepository,
  })  : _projectsRepository = projectsRepository ?? ProjectsApiRepository(),
        _postsRepository = postsRepository ?? PostsApiRepository();

  final ProjectsApiRepository _projectsRepository;
  final PostsApiRepository _postsRepository;

  final List<Project> _projects = [];
  final Set<String> _followedProjectIds = <String>{};
  bool _isFetching = false;
  bool _isTogglingFollow = false;
  String? _lastError;

  List<Project> get projects => List.unmodifiable(_projects);
  Set<String> get followedProjectIds => Set.unmodifiable(_followedProjectIds);
  bool get isFetching => _isFetching;
  bool get isTogglingFollow => _isTogglingFollow;
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

      final postsByProject = <String, List<Post>>{};
      for (final post in posts) {
        postsByProject.putIfAbsent(post.projectId, () => []).add(post);
      }

      _projects
        ..clear()
        ..addAll(
          projects.map((project) {
            final admin = project.admin ?? _fallbackAdmin(project.adminId);
            final relatedPosts = postsByProject[project.id] ?? const <Post>[];

            return project.copyWith(
              posts: relatedPosts,
              admin: admin,
            );
          }),
        );

      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
      debugPrint('Failed to fetch projects from API: $error');
      _projects.clear();
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

  bool isProjectFollowed(String projectId) =>
      _followedProjectIds.contains(projectId);

  Future<void> toggleFollowProject(String projectId) async {
    if (_isTogglingFollow) return;

    final shouldFollow = !_followedProjectIds.contains(projectId);
    _isTogglingFollow = true;
    _lastError = null;
    notifyListeners();

    if (shouldFollow) {
      _followedProjectIds.add(projectId);
    } else {
      _followedProjectIds.remove(projectId);
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
      } else {
        _followedProjectIds.add(projectId);
      }
      _lastError = error.toString();
    } finally {
      _isTogglingFollow = false;
      notifyListeners();
    }
  }

  Admin _fallbackAdmin(String adminId) {
    return Admin(
      id: adminId,
      name: adminId.isEmpty
          ? 'Unknown Admin'
          : 'Admin ${adminId.substring(0, adminId.length >= 6 ? 6 : adminId.length)}',
      username: adminId.isEmpty
          ? '@unknown'
          : '@${adminId.substring(0, adminId.length >= 6 ? 6 : adminId.length)}',
      imageUrl: 'https://placehold.co/80x80/png',
      followers: 0,
    );
  }
}
