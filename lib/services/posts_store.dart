import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/services/firestore_service.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:provider/provider.dart';

class PostsStore extends ChangeNotifier {
  final List<Post> _posts = [];

  List<Post> get posts => _posts;

  // Fetch initial posts from Firestore
  void fetchPostsOnce() async {
    if (_posts.isNotEmpty) return;

    try {
      final postSnapshot = await FirestoreService.getPostsOnce();
      final adminSnapshot = await FirestoreService.getAdminsOnce();
      final projectSnapshot = await FirestoreService.getProjectsOnce();
      //   final admins =
      //   Provider.of<AdminsStore>(context, listen: false).admins;
      // final projects =
      //   Provider.of<ProjectsStore>(context, listen: false).projects;

      for (var doc in postSnapshot.docs) {
        final post = doc.data();

        final project = projectSnapshot.docs
            .firstWhere(
              (p) => p.data().id == post.projectId,
            )
            .data();

        final admin = adminSnapshot.docs
            .firstWhere(
              (a) => a.data().id == post.adminId,
            )
            .data();

        _posts.add(post.copyWith(
          admin: admin,
          project: project,
        ));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error enriching posts: $e');
    }
  }

  void addPost(Post post) async {
    await FirestoreService.addPost(post);
    _posts.add(post);
    notifyListeners();
  }

  Post getPostById(String id) {
    return _posts.firstWhere((Post post) => post.id == id);
  }

  List<Post> getPostsByPrimaryTag(PrimaryTag primaryTag, BuildContext context) {
    final projects =
        Provider.of<ProjectsStore>(context, listen: false).projects;

    debugPrint(
      '🔍 Fetching projects $projects',
    );

    final projectIds = projects
        .where((project) => project.primaryTag == primaryTag)
        .map((project) => project.id)
        .toSet();

    return _posts.where((post) => projectIds.contains(post.projectId)).toList();
  }

  List<Post> getPostsByPriority(priority) {
    return _posts.where((Post post) => post.priority == priority).toList();
  }

  void updatePost(Post updatedPost) async {
    await FirestoreService.updatePost(updatedPost.id, updatedPost);
    final index = _posts.indexWhere((post) => post.id == updatedPost.id);
    if (index != -1) {
      _posts[index] = updatedPost;
      notifyListeners();
    }
  }

  void removePost(String id) async {
    await FirestoreService.deletePost(id);
    _posts.removeWhere((post) => post.id == id);
    notifyListeners();
  }
}
