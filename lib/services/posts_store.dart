import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';

import 'package:blocnet/features/projects/data/dummy/dummy_posts.dart';
import 'package:blocnet/features/projects/data/dummy/dummy_projects.dart';
import 'package:blocnet/features/projects/data/dummy/dummy_admins.dart';

class PostsStore extends ChangeNotifier {
  final List<Post> _posts = [];

  PostsStore() {
    _initializePosts();
  }

  List<Post> get posts => _posts.isNotEmpty ? _posts : [];

  void _initializePosts() {
    _posts.addAll(dummyPosts.map<Post>((post) {
      Admin? admin;
      Project? project;

      try {
        project = dummyProjects.firstWhere((p) => p.id == post.projectId);
      } catch (e) {
        project = null;
      }

      try {
        admin = dummyAdmins.firstWhere((a) => a.id == post.adminId);
      } catch (e) {
        admin = null;
      }

      return post.copyWith(project: project, admin: admin);
    }).toList());

    notifyListeners();
  }

  void reloadPosts() {
    _posts.clear();
    _initializePosts();
    notifyListeners();
  }

  void addPost(Post post) {
    _posts.add(post);
    notifyListeners();
  }
}
