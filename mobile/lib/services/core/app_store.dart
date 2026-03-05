import 'package:flutter/material.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/services/users/admins_store.dart';

class AppStore extends ChangeNotifier {
  final UpdatesStore updatesStore;
  final ProjectsStore projectsStore;
  final AdminsStore adminsStore;

  AppStore()
      : updatesStore = UpdatesStore(),
        projectsStore = ProjectsStore(),
        adminsStore = AdminsStore();

  void reloadAll() {
    // updatesStore.reloadUpdates();
    // projectsStore.reloadProjects();
    // adminsStore.reloadAdmins();
    notifyListeners();
  }
}
