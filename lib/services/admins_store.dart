import 'package:blocnet/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';

class AdminsStore extends ChangeNotifier {
  final List<Admin> _admins = [];

  get admins => _admins;

  void addAdmin(Admin admin) {
    _admins.add(admin);
    notifyListeners();
  }

  void fetchAdminsOnce() async {
    if (_admins.isNotEmpty) return;

    final snapshot = await FirestoreService.getAdminsOnce();

    for (var doc in snapshot.docs) {
      final admin = doc.data();
      _admins.add(admin);
    }

    notifyListeners();
  }
}
