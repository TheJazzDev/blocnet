part of 'community_posts_store.dart';

/// The member's saved (bookmarked) community posts, from `GET /me/bookmarks`.
///
/// Saved posts can be older than anything in the feed, so they live in their
/// own list. Every change to a post passes through [_syncSaved], which keeps
/// this list in step with a save or unsave made anywhere in the app.
mixin _CommunityPostsSavedMixin on ChangeNotifier {
  static const int _savedPageSize = 50;

  CommunityPostsApiRepository get _repository;
  StoreErrorMapper get _errorMapper;

  final List<CommunityPost> _savedPosts = [];
  bool _isLoadingSaved = false;
  bool _hasLoadedSaved = false;
  String? _savedError;

  List<CommunityPost> get savedPosts => List.unmodifiable(_savedPosts);
  bool get isLoadingSaved => _isLoadingSaved;
  bool get hasLoadedSaved => _hasLoadedSaved;
  String? get savedError => _savedError;

  Future<void> loadSavedPosts() async {
    if (_isLoadingSaved) return;
    _isLoadingSaved = true;
    _savedError = null;
    notifyListeners();

    try {
      final items = await _repository.fetchBookmarks(limit: _savedPageSize);
      _savedPosts
        ..clear()
        // The list is by definition saved; the flag may be absent upstream.
        ..addAll(items.map((post) => post.copyWith(isBookmarked: true)));
      _hasLoadedSaved = true;
    } catch (error) {
      _savedError = _errorMapper.map(
        error,
        fallback: 'Could not load saved posts',
      );
    } finally {
      _isLoadingSaved = false;
      notifyListeners();
    }
  }

  CommunityPost? _savedById(String postId) {
    for (final post in _savedPosts) {
      if (post.id == postId) return post;
    }
    return null;
  }

  /// Keeps the saved list in step with [post]: an unsaved post leaves it, a
  /// newly saved one joins the top, a saved one is refreshed in place.
  void _syncSaved(CommunityPost post) {
    final index = _savedPosts.indexWhere((item) => item.id == post.id);
    if (!post.isBookmarked) {
      if (index != -1) _savedPosts.removeAt(index);
      return;
    }
    if (index != -1) {
      _savedPosts[index] = post;
    } else if (_hasLoadedSaved) {
      _savedPosts.insert(0, post);
    }
  }

  void _removeSaved(bool Function(CommunityPost post) test) {
    _savedPosts.removeWhere(test);
  }
}
