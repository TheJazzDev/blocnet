import 'package:flutter/material.dart';
import 'updates_store.dart';
import 'projects_store.dart';
import 'admins_store.dart';

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
