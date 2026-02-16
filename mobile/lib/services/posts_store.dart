import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/secondary_tag_model.dart';
import 'package:blocnet/features/projects/data/repositories/posts_api_repository.dart';
import 'package:blocnet/features/projects/data/repositories/projects_api_repository.dart';
import 'package:flutter/material.dart';

class PostsStore extends ChangeNotifier {
  PostsStore({
    PostsApiRepository? postsRepository,
    ProjectsApiRepository? projectsRepository,
  })  : _postsRepository = postsRepository ?? PostsApiRepository(),
        _projectsRepository = projectsRepository ?? ProjectsApiRepository();

  final PostsApiRepository _postsRepository;
  final ProjectsApiRepository _projectsRepository;

  final List<Post> _posts = [];
  bool _isFetching = false;
  String? _lastError;

  List<Post> get posts => List.unmodifiable(_posts);
  bool get isFetching => _isFetching;
  String? get lastError => _lastError;

  Future<void> fetchPostsOnce() async {
    if (_posts.isNotEmpty || _isFetching) return;
    await refreshPosts();
  }

  Future<void> refreshPosts() async {
    if (_isFetching) return;

    _isFetching = true;
    notifyListeners();

    try {
      final projects = await _projectsRepository.fetchProjects(limit: 500);
      final posts = await _postsRepository.fetchPosts(limit: 500);

      final groupedPosts = <String, List<Post>>{};
      for (final post in posts) {
        groupedPosts.putIfAbsent(post.projectId, () => []).add(post);
      }

      final enrichedProjects = <String, Project>{};
      for (final project in projects) {
        final projectPosts = groupedPosts[project.id] ?? const <Post>[];
        final admin = project.admin ?? _fallbackAdmin(project.adminId);

        enrichedProjects[project.id] = project.copyWith(
          posts: projectPosts,
          admin: admin,
        );
      }

      _posts
        ..clear()
        ..addAll(
          posts.map((post) {
            final project = enrichedProjects[post.projectId];
            final admin =
                post.admin ?? project?.admin ?? _fallbackAdmin(post.adminId);

            return post.copyWith(
              project: project,
              admin: admin,
            );
          }),
        );

      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
      debugPrint('Failed to fetch posts from API: $error');
      _posts.clear();
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> addPost(Post post) async {
    try {
      final created = await _postsRepository.createPost(post);
      final nextPost = created ?? post;

      _posts.add(nextPost);
      notifyListeners();
    } catch (error) {
      debugPrint('Failed to create post: $error');
      rethrow;
    }
  }

  Post getPostById(String id) {
    return _posts.firstWhere((post) => post.id == id);
  }

  List<Post> getPostsByPrimaryTag(PrimaryTag primaryTag, BuildContext context) {
    return _posts
        .where((post) => post.project?.primaryTag == primaryTag)
        .toList();
  }

  List<Post> getPostsByPriority(Priority priority) {
    return _posts.where((post) => post.priority == priority).toList();
  }

  List<Post> getPostsBySecondaryTags(List<SecondaryTag> secondaryTags) {
    if (secondaryTags.isEmpty) return [];

    return _posts.where((post) {
      return post.secondaryTags.any((tag) => secondaryTags.contains(tag));
    }).toList();
  }

  List<Post> getPostsByProjectIdAndPriority(
      String projectId, Priority priority) {
    return _posts
        .where(
            (post) => post.projectId == projectId && post.priority == priority)
        .toList();
  }

  Future<void> updatePost(Post updatedPost) async {
    try {
      final updatedFromApi = await _postsRepository.updatePost(updatedPost);
      final nextPost = updatedFromApi ?? updatedPost;

      final index = _posts.indexWhere((post) => post.id == updatedPost.id);
      if (index != -1) {
        _posts[index] = nextPost;
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Failed to update post: $error');
      rethrow;
    }
  }

  void removePost(String id) {
    _posts.removeWhere((post) => post.id == id);
    notifyListeners();
  }

  Admin _fallbackAdmin(String adminId) {
    return Admin(
      id: adminId,
      name: adminId.isEmpty
          ? 'Unknown Admin'
          : 'Admin ${adminId.substring(0, adminId.length >= 6 ? 6 : adminId.length)}',
      username: adminId.isEmpty
          ? '@unknown'
          : '@${adminId.substring(0, adminId.length >= 6 ? 6 : adminId.length)}',
      imageUrl: 'https://placehold.co/80x80/png',
      followers: 0,
    );
  }
}
