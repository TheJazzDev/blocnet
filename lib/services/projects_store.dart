import 'package:blocnet/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';

class ProjectsStore extends ChangeNotifier {
  final List<Project> _projects = [];

  List<Project> get projects => _projects;

  // Fetch initial posts from Firestore
  void fetchProjectsOnce() async {
    if (_projects.isNotEmpty) return;

    final snapshot = await FirestoreService.getProjectsOnce();
    final postSnapshot = await FirestoreService.getPostsOnce();
    final adminSnapshot = await FirestoreService.getAdminsOnce();

    for (var doc in snapshot.docs) {
      final project = doc.data();

      final posts = postSnapshot.docs
          .where((p) => p.data().projectId == project.id)
          .map((p) => p.data())
          .toList();

      final admin = adminSnapshot.docs
          .firstWhere(
            (a) => a.data().id == project.adminId,
          )
          .data();

      _projects.add(project.copyWith(posts: posts, admin: admin));
    }
    notifyListeners();
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
}
