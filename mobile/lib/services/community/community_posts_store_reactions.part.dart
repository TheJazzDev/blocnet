part of 'community_posts_store.dart';

mixin _CommunityPostsReactionsMixin on ChangeNotifier {
  CommunityPostsApiRepository get _repository;
  StoreErrorMapper get _errorMapper;
  Set<String> get _pendingLikePostIds;
  Set<String> get _pendingBookmarkPostIds;

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
}
