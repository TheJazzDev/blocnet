import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/secondary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/repositories/projects_api_repository.dart';
import 'package:blocnet/features/projects/data/repositories/updates_api_repository.dart';
import 'package:flutter/material.dart';

class UpdatesStore extends ChangeNotifier {
  UpdatesStore({
    UpdatesApiRepository? updatesRepository,
    ProjectsApiRepository? projectsRepository,
  })  : _updatesRepository = updatesRepository ?? UpdatesApiRepository(),
        _projectsRepository = projectsRepository ?? ProjectsApiRepository();

  final UpdatesApiRepository _updatesRepository;
  final ProjectsApiRepository _projectsRepository;

  final List<Update> _updates = [];
  bool _isFetching = false;
  String? _lastError;

  List<Update> get updates => List.unmodifiable(_updates);
  List<Update> get posts => updates;
  bool get isFetching => _isFetching;
  String? get lastError => _lastError;

  Future<void> fetchUpdatesOnce() async {
    if (_updates.isNotEmpty || _isFetching) return;
    await refreshUpdates();
  }

  Future<void> refreshUpdates() async {
    if (_isFetching) return;

    _isFetching = true;
    notifyListeners();

    try {
      final projects = await _projectsRepository.fetchProjects(limit: 500);
      final updates = await _updatesRepository.fetchUpdates(limit: 500);

      final groupedUpdates = <String, List<Update>>{};
      for (final update in updates) {
        groupedUpdates.putIfAbsent(update.projectId, () => []).add(update);
      }

      final enrichedProjects = <String, Project>{};
      for (final project in projects) {
        final projectUpdates = groupedUpdates[project.id] ?? const <Update>[];
        final admin = project.admin ?? _fallbackAdmin(project.adminId);

        enrichedProjects[project.id] = project.copyWith(
          posts: projectUpdates,
          admin: admin,
        );
      }

      _updates
        ..clear()
        ..addAll(
          updates.map((update) {
            final project = enrichedProjects[update.projectId];
            final admin = update.admin ??
                project?.admin ??
                _fallbackAdmin(update.adminId);

            return update.copyWith(project: project, admin: admin);
          }),
        );

      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
      debugPrint('Failed to fetch updates from API: $error');
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<Update?> createUpdate({
    required String projectId,
    required String title,
    required String content,
    required Priority priority,
    List<String>? secondaryTagIds,
  }) async {
    try {
      final created = await _updatesRepository.createUpdate(
        projectId: projectId,
        title: title,
        content: content,
        priority: priority,
        secondaryTagIds: secondaryTagIds,
      );

      if (created != null) {
        _updates.insert(0, created);
        notifyListeners();
      }

      return created;
    } catch (error) {
      debugPrint('Failed to create update: $error');
      rethrow;
    }
  }

  Future<void> addUpdate(Update update) async {
    await createUpdate(
      projectId: update.projectId,
      title: update.title,
      content: update.content,
      priority: update.priority,
    );
  }

  Update getUpdateById(String id) {
    return _updates.firstWhere((update) => update.id == id);
  }

  List<Update> getUpdatesByPrimaryTag(
    PrimaryTag primaryTag,
    BuildContext context,
  ) {
    return _updates
        .where((update) => update.project?.primaryTag == primaryTag)
        .toList();
  }

  List<Update> getUpdatesByPriority(Priority priority) {
    return _updates.where((update) => update.priority == priority).toList();
  }

  List<Update> getUpdatesBySecondaryTags(List<SecondaryTag> secondaryTags) {
    if (secondaryTags.isEmpty) return [];

    return _updates.where((update) {
      return update.secondaryTags.any((tag) => secondaryTags.contains(tag));
    }).toList();
  }

  List<Update> getUpdatesByProjectIdAndPriority(
    String projectId,
    Priority priority,
  ) {
    return _updates
        .where((update) =>
            update.projectId == projectId && update.priority == priority)
        .toList();
  }

  Future<void> updateUpdate(Update updatedUpdate) async {
    try {
      final updatedFromApi =
          await _updatesRepository.updateUpdate(updatedUpdate);
      final nextUpdate = updatedFromApi ?? updatedUpdate;

      final index =
          _updates.indexWhere((update) => update.id == updatedUpdate.id);
      if (index != -1) {
        _updates[index] = nextUpdate;
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Failed to update update: $error');
      rethrow;
    }
  }

  void removeUpdate(String id) {
    _updates.removeWhere((update) => update.id == id);
    notifyListeners();
  }

  // Backward-compatible aliases during migration.
  Future<void> fetchPostsOnce() => fetchUpdatesOnce();
  Future<void> refreshPosts() => refreshUpdates();
  Future<Update?> createPost({
    required String projectId,
    required String title,
    required String content,
    required Priority priority,
    List<String>? secondaryTagIds,
  }) =>
      createUpdate(
        projectId: projectId,
        title: title,
        content: content,
        priority: priority,
        secondaryTagIds: secondaryTagIds,
      );
  Future<void> addPost(Update post) => addUpdate(post);
  Update getPostById(String id) => getUpdateById(id);
  List<Update> getPostsByPrimaryTag(
          PrimaryTag primaryTag, BuildContext context) =>
      getUpdatesByPrimaryTag(primaryTag, context);
  List<Update> getPostsByPriority(Priority priority) =>
      getUpdatesByPriority(priority);
  List<Update> getPostsBySecondaryTags(List<SecondaryTag> secondaryTags) =>
      getUpdatesBySecondaryTags(secondaryTags);
  List<Update> getPostsByProjectIdAndPriority(
          String projectId, Priority priority) =>
      getUpdatesByProjectIdAndPriority(projectId, priority);
  Future<void> updatePost(Update updatedPost) => updateUpdate(updatedPost);
  void removePost(String id) => removeUpdate(id);

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
}
