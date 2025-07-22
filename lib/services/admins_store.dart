import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';

class AdminsStore extends ChangeNotifier {
  final List<Admin> _admins = [
    Admin(
      id: 'admin1',
      name: 'Damsel',
      username: '@damsel',
      imageUrl:
          'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
      followers: 3567,
    ),
    Admin(
      id: 'admin2',
      name: 'Omobola Ijagba',
      username: 'omo_agba',
      imageUrl:
          'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
      followers: 898,
    ),
    Admin(
      id: 'admin3',
      name: 'Jazz Dev',
      username: 'jazz__dev',
      imageUrl:
          'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
      followers: 1120,
    ),
  ];

  get admins => _admins;

  void addAdmin(Admin admin) {
    _admins.add(admin);
    notifyListeners();
  }
}
