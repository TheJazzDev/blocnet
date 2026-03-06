part of 'community_posts_store.dart';

mixin _CommunityPostsReactionsMixin on ChangeNotifier {
  CommunityPostsApiRepository get _repository;
  StoreErrorMapper get _errorMapper;
  Set<String> get _pendingLikePostIds;
  Set<String> get _pendingBookmarkPostIds;
  Set<String> get _pendingLikeCommentIds;
  Map<String, List<CommunityPostComment>> get _commentsByPostId;

  set _lastError(String? value);

  CommunityPost? postById(String postId);
  void _replacePost(CommunityPost post);

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
      _lastError = _errorMapper.map(error, fallback: 'Unable to update like');
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
      _lastError =
          _errorMapper.map(error, fallback: 'Unable to update bookmark');
    } finally {
      _pendingBookmarkPostIds.remove(postId);
      notifyListeners();
    }
  }

  Future<void> toggleLikeCommunityPostComment(String commentId) async {
    if (_pendingLikeCommentIds.contains(commentId)) return;
    final current = _findCommentById(commentId);
    if (current == null) return;

    _pendingLikeCommentIds.add(commentId);
    final optimisticLiked = !current.isLiked;
    final optimisticLikes = optimisticLiked
        ? current.likesCount + 1
        : (current.likesCount > 0 ? current.likesCount - 1 : 0);
    _replaceCommentInAllCaches(
      commentId,
      _copyWithReactionState(
        current,
        isLiked: optimisticLiked,
        likesCount: optimisticLikes,
      ),
    );
    notifyListeners();

    try {
      final updated = current.isLiked
          ? await _repository.unlikeComment(commentId)
          : await _repository.likeComment(commentId);
      if (updated != null) {
        _replaceCommentInAllCaches(commentId, updated);
      }
      _lastError = null;
    } catch (error) {
      _replaceCommentInAllCaches(commentId, current);
      _lastError =
          _errorMapper.map(error, fallback: 'Unable to update comment like');
    } finally {
      _pendingLikeCommentIds.remove(commentId);
      notifyListeners();
    }
  }

  Future<void> likeCommunityPostComment(String commentId) {
    return toggleLikeCommunityPostComment(commentId);
  }

  CommunityPostComment? _findCommentById(String commentId) {
    for (final comments in _commentsByPostId.values) {
      for (final comment in comments) {
        if (comment.id == commentId) {
          return comment;
        }
      }
    }
    return null;
  }

  void _replaceCommentInAllCaches(
    String commentId,
    CommunityPostComment replacement,
  ) {
    for (final postId in _commentsByPostId.keys) {
      final items = <CommunityPostComment>[
        ...(_commentsByPostId[postId] ?? const <CommunityPostComment>[]),
      ];
      final index = items.indexWhere((item) => item.id == commentId);
      if (index == -1) continue;
      items[index] = replacement;
      _commentsByPostId[postId] = items;
    }
  }

  CommunityPostComment _copyWithReactionState(
    CommunityPostComment current, {
    required bool isLiked,
    required int likesCount,
  }) {
    return CommunityPostComment(
      id: current.id,
      postId: current.postId,
      authorId: current.authorId,
      content: current.content,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      likesCount: likesCount < 0 ? 0 : likesCount,
      isLiked: isLiked,
      admin: current.admin,
      replyToId: current.replyToId,
      replyToData: current.replyToData,
    );
  }
}
