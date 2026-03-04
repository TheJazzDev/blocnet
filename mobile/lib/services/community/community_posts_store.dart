import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/features/community/application/community_comment_sync_helper.dart';
import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/features/community/data/repositories/community_posts_api_repository.dart';
import 'package:blocnet/shared/application/errors/store_error_mapper.dart';
import 'package:blocnet/shared/application/realtime/realtime_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'community_posts_store_realtime.part.dart';
part 'community_posts_store_reactions.part.dart';

class CommunityPostsStore extends ChangeNotifier
    with _CommunityPostsRealtimeMixin, _CommunityPostsReactionsMixin {
  CommunityPostsStore({CommunityPostsApiRepository? repository})
      : _repository = repository ?? CommunityPostsApiRepository();

  static const int _commentPageSize = 40;

  @override
  final CommunityPostsApiRepository _repository;
  @override
  final StoreErrorMapper _errorMapper = const StoreErrorMapper();
  @override
  final RealtimeCoordinator _realtimeCoordinator = RealtimeCoordinator();

  final List<CommunityPost> _posts = [];
  @override
  final Map<String, List<CommunityPostComment>> _commentsByPostId = {};
  final Map<String, bool> _hasMoreCommentsByPostId = {};
  final Set<String> _loadingCommentPostIds = <String>{};
  @override
  final Set<String> _pendingLikePostIds = <String>{};
  @override
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
      final previouslyCommentedById = <String, bool>{
        for (final post in _posts)
          if (post.isCommented) post.id: true,
      };
      _posts
        ..clear()
        ..addAll(
          items.map(
            (item) => item.copyWith(
              isCommented: item.isCommented ||
                  (previouslyCommentedById[item.id] ?? false),
            ),
          ),
        );
    } catch (error) {
      _lastError = _errorMapper.map(error, fallback: 'Unable to load posts');
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
      _lastError = _errorMapper.map(error, fallback: 'Unable to publish post');
      rethrow;
    } finally {
      _isSubmittingPost = false;
      notifyListeners();
    }
  }

  @override
  CommunityPost? postById(String postId) {
    for (final post in _posts) {
      if (post.id == postId) return post;
    }
    return null;
  }

  @override
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

  bool hasMoreCommentsForPost(String postId) {
    return _hasMoreCommentsByPostId[postId] ?? true;
  }

  Future<void> fetchComments(String postId, {bool force = false}) async {
    if (_loadingCommentPostIds.contains(postId)) return;
    if (!force && (_commentsByPostId[postId]?.isNotEmpty ?? false)) return;

    _loadingCommentPostIds.add(postId);
    notifyListeners();

    try {
      await _fetchLatestComments(postId, replaceExisting: true);
      _lastError = null;
    } catch (error) {
      _lastError = _errorMapper.map(
        error,
        fallback: 'Unable to load discussion comments',
      );
    } finally {
      _loadingCommentPostIds.remove(postId);
      notifyListeners();
    }
  }

  @override
  Future<void> refreshLatestComments(String postId) async {
    if (_loadingCommentPostIds.contains(postId)) return;
    if (postId.trim().isEmpty) return;

    try {
      await _fetchLatestComments(postId, replaceExisting: false);
      _lastError = null;
      notifyListeners();
    } catch (error) {
      _lastError = _errorMapper.map(
        error,
        fallback: 'Unable to refresh discussion comments',
      );
      notifyListeners();
    }
  }

  Future<void> loadOlderComments(String postId) async {
    if (_loadingCommentPostIds.contains(postId)) return;
    if (!hasMoreCommentsForPost(postId)) return;

    final existing =
        _commentsByPostId[postId] ?? const <CommunityPostComment>[];
    if (existing.isEmpty) {
      await fetchComments(postId, force: true);
      return;
    }

    final cursor = existing.first;
    _loadingCommentPostIds.add(postId);
    notifyListeners();
    try {
      final older = await _repository.fetchComments(
        postId,
        limit: _commentPageSize,
        beforeCreatedAt: cursor.createdAt.toUtc().toIso8601String(),
        beforeId: cursor.id,
      );
      if (older.isEmpty) {
        _hasMoreCommentsByPostId[postId] = false;
      } else {
        _commentsByPostId[postId] = _mergeComments(existing, older);
        _hasMoreCommentsByPostId[postId] = older.length >= _commentPageSize;
      }
      _lastError = null;
    } catch (error) {
      _lastError = _errorMapper.map(
        error,
        fallback: 'Unable to load older comments',
      );
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

    _commentsByPostId[postId] = _mergeComments(
      _commentsByPostId[postId] ?? const <CommunityPostComment>[],
      [created],
    );

    final post = postById(postId);
    if (post != null) {
      _replacePost(
        post.copyWith(
          commentsCount: post.commentsCount + 1,
          isCommented: true,
        ),
      );
    }

    notifyListeners();
    return created;
  }

  void watchCommentsRealtime(String postId) {
    if (!AppConfig.isSupabaseConfigured || postId.isEmpty) return;
    if (_realtimeCoordinator.hasChannel(postId)) return;

    _startCommentRealtimeChannel(postId);
  }

  void unwatchCommentsRealtime(String postId) {
    _realtimeCoordinator.cancelDebounce('community-comment-refetch-$postId');
    _realtimeCoordinator.cancelDebounce('community-post-refresh-$postId');
    _realtimeCoordinator.cancelRecovery(postId);
    if (!_realtimeCoordinator.hasChannel(postId)) return;
    debugPrint('[RT][CommunityComment] unsubscribe postId=$postId');
    _realtimeCoordinator.removeChannel(postId);
  }

  @override
  void _replacePost(CommunityPost post) {
    final index = _posts.indexWhere((item) => item.id == post.id);
    if (index == -1) {
      _posts.insert(0, post);
      return;
    }

    final existing = _posts[index];
    _posts[index] = post.copyWith(
      isCommented: post.isCommented || existing.isCommented,
    );
  }

  Future<void> _fetchLatestComments(
    String postId, {
    required bool replaceExisting,
  }) async {
    final latest =
        await _repository.fetchComments(postId, limit: _commentPageSize);
    if (replaceExisting) {
      _commentsByPostId[postId] =
          CommunityCommentSyncHelper.sortComments(latest);
      _hasMoreCommentsByPostId[postId] = latest.length >= _commentPageSize;
      _syncCommentedState(postId, latest);
      return;
    }

    final existing =
        _commentsByPostId[postId] ?? const <CommunityPostComment>[];
    _commentsByPostId[postId] = _mergeComments(existing, latest);
    if (latest.length >= _commentPageSize) {
      _hasMoreCommentsByPostId[postId] = true;
    }
    _syncCommentedState(
      postId,
      _commentsByPostId[postId] ?? const <CommunityPostComment>[],
    );
  }

  void _syncCommentedState(
    String postId,
    List<CommunityPostComment> comments,
  ) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id.trim();
    if (currentUserId == null || currentUserId.isEmpty) {
      return;
    }

    final hasCurrentUserComment = comments.any(
      (comment) => comment.authorId.trim() == currentUserId,
    );
    if (!hasCurrentUserComment) {
      return;
    }

    final post = postById(postId);
    if (post == null || post.isCommented) {
      return;
    }

    _replacePost(post.copyWith(isCommented: true));
  }

  @override
  List<CommunityPostComment> _mergeComments(
    List<CommunityPostComment> base,
    List<CommunityPostComment> incoming,
  ) {
    return CommunityCommentSyncHelper.mergeComments(base, incoming);
  }

  @override
  void dispose() {
    _realtimeCoordinator.dispose();
    super.dispose();
  }
}
