import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/services/projects/legacy_update_reactions_sync.dart';
import 'package:blocnet/services/projects/update_reactions_repository.dart';
import 'package:flutter/foundation.dart';

/// A toggle the member made that the [Update] snapshot on screen may not
/// reflect yet.
class _Override {
  const _Override(this.active, this.count);

  final bool active;
  final int count;
}

/// Likes and saves on updates, backed by the server.
///
/// Replaces the old local-only `UpdateLikesStore` / `UpdateBookmarksStore`.
/// The feed's [Update] carries the server truth (`likedByMe`, `likesCount`,
/// ...). A toggle is applied optimistically as an override on top of it, then
/// replaced by what the server answers, or reverted if the call fails (the
/// caller shows the error). An override is dropped as soon as a snapshot
/// arrives that already agrees with it, so a refreshed feed wins again.
class UpdateReactionsStore extends ChangeNotifier {
  UpdateReactionsStore({
    UpdateReactionsRepository? repository,
    LegacyUpdateReactionsSync? legacySync,
  }) : _repository = repository ?? UpdateReactionsRepository() {
    _legacySync =
        legacySync ?? LegacyUpdateReactionsSync(repository: _repository);
  }

  final UpdateReactionsRepository _repository;
  late final LegacyUpdateReactionsSync _legacySync;

  final Map<String, _Override> _likes = {};
  final Map<String, _Override> _bookmarks = {};
  final Set<String> _pendingLikes = {};
  final Set<String> _pendingBookmarks = {};

  String? _userId;
  bool _legacySyncStarted = false;
  final List<Update> _saved = [];
  bool _isLoadingSaved = false;
  bool _savedLoaded = false;
  String? _savedError;

  List<Update> get savedUpdates => List.unmodifiable(_saved);
  bool get isLoadingSaved => _isLoadingSaved;
  bool get hasLoadedSaved => _savedLoaded;
  String? get savedError => _savedError;

  // ---- Reads -------------------------------------------------------------

  bool isLiked(Update update) =>
      _likeOverride(update)?.active ?? update.likedByMe;

  int likesCount(Update update) =>
      _likeOverride(update)?.count ?? update.likesCount;

  bool isBookmarked(Update update) =>
      _bookmarkOverride(update)?.active ?? update.bookmarkedByMe;

  int bookmarksCount(Update update) =>
      _bookmarkOverride(update)?.count ?? update.bookmarksCount;

  _Override? _likeOverride(Update update) =>
      _resolve(_likes, _pendingLikes, update.id, update.likedByMe);

  _Override? _bookmarkOverride(Update update) =>
      _resolve(_bookmarks, _pendingBookmarks, update.id, update.bookmarkedByMe);

  static _Override? _resolve(
    Map<String, _Override> overrides,
    Set<String> pending,
    String id,
    bool snapshot,
  ) {
    final override = overrides[id];
    if (override == null) return null;
    // The snapshot caught up (a refetch after the toggle): trust it again,
    // counts included, since it also carries other members' changes.
    if (override.active == snapshot && !pending.contains(id)) {
      overrides.remove(id);
      return null;
    }
    return override;
  }

  // ---- Writes ------------------------------------------------------------

  /// Flips the like. Returns the new state; throws (after reverting) when the
  /// server call fails. A tap while a call for the same update is in flight
  /// is ignored and returns the current state.
  Future<bool> toggleLike(Update update) async {
    final id = update.id;
    final wasLiked = isLiked(update);
    if (_pendingLikes.contains(id)) return wasLiked;

    final previous = _likes[id];
    final count = likesCount(update);
    final next = !wasLiked;
    _pendingLikes.add(id);
    _likes[id] = _Override(next, _bump(count, next));
    _notify();

    try {
      final result = await _repository.setLiked(id, next);
      _likes[id] = _Override(result.liked, result.likesCount);
      return result.liked;
    } catch (_) {
      _restore(_likes, id, previous);
      rethrow;
    } finally {
      _pendingLikes.remove(id);
      _notify();
    }
  }

  /// Flips the save, with the same contract as [toggleLike]. The Saved list
  /// follows: an unsave removes the row, a save puts it on top.
  Future<bool> toggleBookmark(Update update) async {
    final id = update.id;
    final wasSaved = isBookmarked(update);
    if (_pendingBookmarks.contains(id)) return wasSaved;

    final previous = _bookmarks[id];
    final count = bookmarksCount(update);
    final next = !wasSaved;
    final savedIndex = _saved.indexWhere((row) => row.id == id);
    final savedRow = savedIndex >= 0 ? _saved[savedIndex] : null;

    _pendingBookmarks.add(id);
    _bookmarks[id] = _Override(next, _bump(count, next));
    if (!next && savedIndex >= 0) _saved.removeAt(savedIndex);
    _notify();

    try {
      final result = await _repository.setBookmarked(id, next);
      _bookmarks[id] = _Override(result.bookmarked, result.bookmarksCount);
      if (result.bookmarked && _savedLoaded) {
        _saved.removeWhere((row) => row.id == id);
        _saved.insert(0, update);
      }
      return result.bookmarked;
    } catch (_) {
      _restore(_bookmarks, id, previous);
      if (savedRow != null && !_saved.any((row) => row.id == id)) {
        _saved.insert(savedIndex.clamp(0, _saved.length), savedRow);
      }
      rethrow;
    } finally {
      _pendingBookmarks.remove(id);
      _notify();
    }
  }

  static int _bump(int count, bool up) =>
      up ? count + 1 : (count > 0 ? count - 1 : 0);

  static void _restore(
    Map<String, _Override> map,
    String id,
    _Override? previous,
  ) {
    if (previous == null) {
      map.remove(id);
    } else {
      map[id] = previous;
    }
  }

  // ---- Saved list --------------------------------------------------------

  Future<void> refreshSaved() async {
    if (_isLoadingSaved) return;
    _isLoadingSaved = true;
    _notify();

    try {
      final rows = await _repository.fetchSavedUpdates(limit: 100);
      _saved
        ..clear()
        ..addAll(rows);
      _savedLoaded = true;
      _savedError = null;
    } catch (error) {
      _savedError = error.toString();
    } finally {
      _isLoadingSaved = false;
      _notify();
    }
  }

  Future<void> loadSavedOnce() async {
    if (_savedLoaded) return;
    await refreshSaved();
  }

  bool _disposed = false;

  /// A toggle can finish after the store is gone (sign-out, tests).
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ---- Account scope -----------------------------------------------------

  /// Binds the store to the signed-in member. A different member (or none)
  /// drops everything the previous one saw. A signed-in member triggers the
  /// one-time move of the phone's old local likes and saves.
  void ensureUserScope(String? userId) {
    final normalized = userId?.trim();
    final next = (normalized == null || normalized.isEmpty) ? null : normalized;
    if (next != _userId) {
      _userId = next;
      _likes.clear();
      _bookmarks.clear();
      _saved.clear();
      _savedLoaded = false;
      _savedError = null;
      // No notify: this runs inside a provider update, mid-build.
    }
    if (next != null && !_legacySyncStarted) {
      _legacySyncStarted = true;
      syncLegacyReactions();
    }
  }

  /// Runs the one-time import; refreshes the Saved list if it was already
  /// showing and something was imported, since those saves belong in it.
  Future<LegacySyncOutcome> syncLegacyReactions() async {
    final outcome = await _legacySync.runOnce();
    if (outcome == LegacySyncOutcome.imported && _savedLoaded) {
      await refreshSaved();
    }
    return outcome;
  }
}
