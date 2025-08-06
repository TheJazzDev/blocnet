import 'package:flutter/material.dart';
import 'posts_store.dart';
import 'projects_store.dart';
import 'admins_store.dart';

class AppStore extends ChangeNotifier {
  final PostsStore postsStore;
  final ProjectsStore projectsStore;
  final AdminsStore adminsStore;

  AppStore()
      : postsStore = PostsStore(),
        projectsStore = ProjectsStore(),
        adminsStore = AdminsStore();

  void reloadAll() {
    // postsStore.reloadPosts();
    // projectsStore.reloadProjects();
    // adminsStore.reloadAdmins();
    notifyListeners();
  }
}
