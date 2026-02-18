import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/features/community/data/repositories/community_posts_api_repository.dart';
import 'package:flutter/material.dart';

class CommunityPostsStore extends ChangeNotifier {
  CommunityPostsStore({CommunityPostsApiRepository? repository})
      : _repository = repository ?? CommunityPostsApiRepository();

  final CommunityPostsApiRepository _repository;

  final List<CommunityPost> _posts = [];
  final Map<String, List<CommunityPostComment>> _commentsByPostId = {};
  final Set<String> _loadingCommentPostIds = <String>{};
  final Set<String> _pendingLikePostIds = <String>{};
  final Set<String> _pendingBookmarkPostIds = <String>{};

  bool _isFetchingPosts = false;
  bool _isSubmittingPost = false;
  String? _lastError;

  List<CommunityPost> get posts => List.unmodifiable(_posts);
  bool get isFetchingPosts => _isFetchingPosts;
  bool get isSubmittingPost => _isSubmittingPost;
  String? get lastError => _lastError;

  Future<void> fetchPostsOnce() async {
    if (_posts.isNotEmpty || _isFetchingPosts) return;
    await refreshPosts();
  }

  Future<void> refreshPosts() async {
    if (_isFetchingPosts) return;

    _isFetchingPosts = true;
    _lastError = null;
    notifyListeners();

    try {
      final items = await _repository.fetchPosts(limit: 500);
      _posts
        ..clear()
        ..addAll(items);
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isFetchingPosts = false;
      notifyListeners();
    }
  }

  Future<CommunityPost?> createPost({
    required String content,
    required CommunityTopic topic,
  }) async {
    if (_isSubmittingPost) return null;

    _isSubmittingPost = true;
    _lastError = null;
    notifyListeners();

    try {
      final created = await _repository.createPost(
        content: content,
        topic: topic,
      );

      if (created != null) {
        _posts.insert(0, created);
      }

      return created;
    } catch (error) {
      _lastError = error.toString();
      rethrow;
    } finally {
      _isSubmittingPost = false;
      notifyListeners();
    }
  }

  CommunityPost? postById(String postId) {
    for (final post in _posts) {
      if (post.id == postId) return post;
    }
    return null;
  }

  Future<CommunityPost?> fetchPostById(String postId) async {
    final existing = postById(postId);
    if (existing != null) {
      return existing;
    }

    final fetched = await _repository.fetchPostById(postId);
    if (fetched == null) {
      return null;
    }

    _replacePost(fetched);
    notifyListeners();
    return fetched;
  }

  List<CommunityPostComment> commentsForPost(String postId) {
    return List.unmodifiable(_commentsByPostId[postId] ?? const []);
  }

  bool isLoadingCommentsForPost(String postId) {
    return _loadingCommentPostIds.contains(postId);
  }

  Future<void> fetchComments(String postId, {bool force = false}) async {
    if (_loadingCommentPostIds.contains(postId)) return;
    if (!force && (_commentsByPostId[postId]?.isNotEmpty ?? false)) return;

    _loadingCommentPostIds.add(postId);
    notifyListeners();

    try {
      final comments = await _repository.fetchComments(postId);
      _commentsByPostId[postId] = comments;
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _loadingCommentPostIds.remove(postId);
      notifyListeners();
    }
  }

  Future<CommunityPostComment?> createComment({
    required String postId,
    required String content,
  }) async {
    final created = await _repository.createComment(
      postId: postId,
      content: content,
    );

    if (created == null) {
      return null;
    }

    final next = [
      ...(_commentsByPostId[postId] ?? const <CommunityPostComment>[]),
      created,
    ];
    _commentsByPostId[postId] = next;

    final post = postById(postId);
    if (post != null) {
      _replacePost(post.copyWith(commentsCount: post.commentsCount + 1));
    }

    notifyListeners();
    return created;
  }

  Future<void> toggleLike(String postId) async {
    if (_pendingLikePostIds.contains(postId)) return;

    final current = postById(postId);
    if (current == null) return;

    _pendingLikePostIds.add(postId);
    notifyListeners();

    try {
      final updated = current.isLiked
          ? await _repository.unlikePost(postId)
          : await _repository.likePost(postId);

      if (updated != null) {
        _replacePost(updated);
      }
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _pendingLikePostIds.remove(postId);
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(String postId) async {
    if (_pendingBookmarkPostIds.contains(postId)) return;

    final current = postById(postId);
    if (current == null) return;

    _pendingBookmarkPostIds.add(postId);
    notifyListeners();

    try {
      final updated = current.isBookmarked
          ? await _repository.unbookmarkPost(postId)
          : await _repository.bookmarkPost(postId);

      if (updated != null) {
        _replacePost(updated);
      }
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _pendingBookmarkPostIds.remove(postId);
      notifyListeners();
    }
  }

  void _replacePost(CommunityPost post) {
    final index = _posts.indexWhere((item) => item.id == post.id);
    if (index == -1) {
      _posts.insert(0, post);
      return;
    }

    _posts[index] = post;
  }
}
