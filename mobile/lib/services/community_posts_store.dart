import 'dart:async';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/features/community/data/repositories/community_posts_api_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityPostsStore extends ChangeNotifier {
  CommunityPostsStore({CommunityPostsApiRepository? repository})
      : _repository = repository ?? CommunityPostsApiRepository();

  static const int _commentPageSize = 40;
  static const Duration _refetchDebounce = Duration(milliseconds: 450);
  static const Duration _channelRecoveryDelay = Duration(seconds: 2);

  final CommunityPostsApiRepository _repository;

  final List<CommunityPost> _posts = [];
  final Map<String, List<CommunityPostComment>> _commentsByPostId = {};
  final Map<String, bool> _hasMoreCommentsByPostId = {};
  final Set<String> _loadingCommentPostIds = <String>{};
  final Set<String> _pendingLikePostIds = <String>{};
  final Set<String> _pendingBookmarkPostIds = <String>{};
  final Map<String, RealtimeChannel> _commentChannelsByPostId = {};
  final Map<String, Timer> _commentRefetchDebounceTimers = {};
  final Map<String, Timer> _commentChannelRecoveryTimers = {};
  final Map<String, Timer> _postRefreshDebounceTimers = {};

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
      _lastError = error.toString();
    } finally {
      _loadingCommentPostIds.remove(postId);
      notifyListeners();
    }
  }

  Future<void> refreshLatestComments(String postId) async {
    if (_loadingCommentPostIds.contains(postId)) return;
    if (postId.trim().isEmpty) return;

    try {
      await _fetchLatestComments(postId, replaceExisting: false);
      _lastError = null;
      notifyListeners();
    } catch (error) {
      _lastError = error.toString();
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

    _commentsByPostId[postId] = _mergeComments(
      _commentsByPostId[postId] ?? const <CommunityPostComment>[],
      [created],
    );

    final post = postById(postId);
    if (post != null) {
      _replacePost(post.copyWith(commentsCount: post.commentsCount + 1));
    }

    notifyListeners();
    return created;
  }

  void watchCommentsRealtime(String postId) {
    if (!AppConfig.isSupabaseConfigured || postId.isEmpty) return;
    if (_commentChannelsByPostId.containsKey(postId)) return;

    _startCommentRealtimeChannel(postId);
  }

  void unwatchCommentsRealtime(String postId) {
    _commentRefetchDebounceTimers.remove(postId)?.cancel();
    _commentChannelRecoveryTimers.remove(postId)?.cancel();
    _postRefreshDebounceTimers.remove(postId)?.cancel();
    final channel = _commentChannelsByPostId.remove(postId);
    if (channel == null) return;
    debugPrint('[RT][CommunityComment] unsubscribe postId=$postId');
    Supabase.instance.client.removeChannel(channel);
  }

  Future<void> toggleLike(String postId) async {
    if (_pendingLikePostIds.contains(postId)) return;

    final current = postById(postId);
    if (current == null) return;

    _pendingLikePostIds.add(postId);
    final optimisticLiked = !current.isLiked;
    final optimisticLikes = optimisticLiked
        ? current.likesCount + 1
        : (current.likesCount > 0 ? current.likesCount - 1 : 0);
    _replacePost(
      current.copyWith(
        isLiked: optimisticLiked,
        likesCount: optimisticLikes,
      ),
    );
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
      _replacePost(current);
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
    _replacePost(
      current.copyWith(
        isBookmarked: !current.isBookmarked,
      ),
    );
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
      _replacePost(current);
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

  Future<void> _fetchLatestComments(
    String postId, {
    required bool replaceExisting,
  }) async {
    final latest =
        await _repository.fetchComments(postId, limit: _commentPageSize);
    if (replaceExisting) {
      _commentsByPostId[postId] = _sortComments(latest);
      _hasMoreCommentsByPostId[postId] = latest.length >= _commentPageSize;
      return;
    }

    final existing =
        _commentsByPostId[postId] ?? const <CommunityPostComment>[];
    _commentsByPostId[postId] = _mergeComments(existing, latest);
    if (latest.length >= _commentPageSize) {
      _hasMoreCommentsByPostId[postId] = true;
    }
  }

  void _startCommentRealtimeChannel(String postId) {
    debugPrint('[RT][CommunityComment] subscribe start postId=$postId');
    final channel = Supabase.instance.client
        .channel('community-comments-$postId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'CommunityPostComment',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'postId',
            value: postId,
          ),
          callback: (payload) {
            debugPrint(
              '[RT][CommunityComment] insert received postId=$postId '
              'new=${payload.newRecord}',
            );
            final insertedNew = _applyRealtimeCommentInsert(
              postId,
              payload.newRecord,
            );
            _scheduleCommentsFallbackRefresh(postId);
            if (insertedNew) {
              _incrementPostCommentCount(postId);
            }
            _schedulePostRefresh(postId);
          },
        )
        .subscribe((status, [error]) {
      debugPrint(
        '[RT][CommunityComment] subscribe status postId=$postId '
        'status=$status error=$error',
      );
      _handleCommentSubscribeStatus(postId, status);
    });

    _commentChannelsByPostId[postId] = channel;
  }

  bool _applyRealtimeCommentInsert(
      String postId, Map<String, dynamic> newRecord) {
    final parsed = _parseRealtimeComment(postId, newRecord);
    if (parsed == null) {
      return false;
    }
    final existing =
        _commentsByPostId[postId] ?? const <CommunityPostComment>[];
    final alreadyPresent = existing.any((comment) => comment.id == parsed.id);
    _commentsByPostId[postId] = _mergeComments(existing, [parsed]);
    notifyListeners();
    return !alreadyPresent;
  }

  CommunityPostComment? _parseRealtimeComment(
    String postId,
    Map<String, dynamic> newRecord,
  ) {
    try {
      final record = Map<String, dynamic>.from(newRecord);
      final status = (record['status'] ?? 'active').toString().toLowerCase();
      if (status != 'active') {
        return null;
      }
      record['postId'] = record['postId'] ?? postId;
      final parsed = CommunityPostComment.fromApi(record);
      if (parsed.id.trim().isEmpty || parsed.postId.trim().isEmpty) {
        return null;
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  void _incrementPostCommentCount(String postId) {
    final post = postById(postId);
    if (post == null) return;
    _replacePost(post.copyWith(commentsCount: post.commentsCount + 1));
    notifyListeners();
  }

  void _scheduleCommentsFallbackRefresh(String postId) {
    _commentRefetchDebounceTimers.remove(postId)?.cancel();
    _commentRefetchDebounceTimers[postId] = Timer(_refetchDebounce, () {
      _commentRefetchDebounceTimers.remove(postId);
      unawaited(refreshLatestComments(postId));
    });
  }

  void _schedulePostRefresh(String postId) {
    _postRefreshDebounceTimers.remove(postId)?.cancel();
    _postRefreshDebounceTimers[postId] = Timer(_refetchDebounce, () {
      _postRefreshDebounceTimers.remove(postId);
      unawaited(fetchPostById(postId));
    });
  }

  void _handleCommentSubscribeStatus(
    String postId,
    RealtimeSubscribeStatus status,
  ) {
    if (status == RealtimeSubscribeStatus.subscribed) {
      _commentChannelRecoveryTimers.remove(postId)?.cancel();
      unawaited(refreshLatestComments(postId));
      return;
    }

    if (status == RealtimeSubscribeStatus.channelError ||
        status == RealtimeSubscribeStatus.timedOut ||
        status == RealtimeSubscribeStatus.closed) {
      _scheduleCommentChannelRecovery(postId);
    }
  }

  void _scheduleCommentChannelRecovery(String postId) {
    if (_commentChannelRecoveryTimers.containsKey(postId)) return;
    _commentChannelRecoveryTimers[postId] = Timer(_channelRecoveryDelay, () {
      _commentChannelRecoveryTimers.remove(postId);
      final existing = _commentChannelsByPostId.remove(postId);
      if (existing == null) return;

      Supabase.instance.client.removeChannel(existing);
      _startCommentRealtimeChannel(postId);
      unawaited(refreshLatestComments(postId));
    });
  }

  List<CommunityPostComment> _mergeComments(
    List<CommunityPostComment> base,
    List<CommunityPostComment> incoming,
  ) {
    final byId = <String, CommunityPostComment>{};
    for (final item in base) {
      if (item.id.trim().isEmpty) continue;
      byId[item.id] = item;
    }

    for (final item in incoming) {
      if (item.id.trim().isEmpty) continue;
      final existing = byId[item.id];
      if (existing == null) {
        byId[item.id] = item;
        continue;
      }
      byId[item.id] = _mergeComment(existing, item);
    }

    return _sortComments(byId.values.toList(growable: false));
  }

  CommunityPostComment _mergeComment(
    CommunityPostComment existing,
    CommunityPostComment incoming,
  ) {
    return CommunityPostComment(
      id: existing.id,
      postId: existing.postId,
      authorId: incoming.authorId.trim().isNotEmpty
          ? incoming.authorId
          : existing.authorId,
      content: incoming.content.trim().isNotEmpty
          ? incoming.content
          : existing.content,
      createdAt: incoming.createdAt.isBefore(existing.createdAt)
          ? incoming.createdAt
          : existing.createdAt,
      updatedAt: incoming.updatedAt.isAfter(existing.updatedAt)
          ? incoming.updatedAt
          : existing.updatedAt,
      admin: incoming.admin ?? existing.admin,
    );
  }

  List<CommunityPostComment> _sortComments(List<CommunityPostComment> items) {
    items.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return items;
  }

  @override
  void dispose() {
    for (final timer in _commentRefetchDebounceTimers.values) {
      timer.cancel();
    }
    _commentRefetchDebounceTimers.clear();

    for (final timer in _commentChannelRecoveryTimers.values) {
      timer.cancel();
    }
    _commentChannelRecoveryTimers.clear();

    for (final timer in _postRefreshDebounceTimers.values) {
      timer.cancel();
    }
    _postRefreshDebounceTimers.clear();

    for (final channel in _commentChannelsByPostId.values) {
      Supabase.instance.client.removeChannel(channel);
    }
    _commentChannelsByPostId.clear();
    super.dispose();
  }
}
