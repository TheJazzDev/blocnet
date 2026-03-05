import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:flutter/material.dart';

class AdminsStore extends ChangeNotifier {
  final List<Admin> _admins = [];

  List<Admin> get admins => List.unmodifiable(_admins);

  void addAdmin(Admin admin) {
    final exists = _admins.any((item) => item.id == admin.id);
    if (!exists) {
      _admins.add(admin);
      notifyListeners();
    }
  }

  void setAdmins(Iterable<Admin> admins) {
    _admins
      ..clear()
      ..addAll(admins);
    notifyListeners();
  }

  Future<void> fetchAdminsOnce() async {
    // Admin entities are currently hydrated from project/post payloads.
    // Dedicated admin listing endpoint can replace this in the next iteration.
    return;
  }
}
