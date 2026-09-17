import 'package:blocnet/features/hunter/data/models/hunter_leaderboard_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/hunter/data/repositories/hunter_reliability_api_repository.dart';
import 'package:flutter/foundation.dart';

/// Reads one page of `GET /hunters/leaderboard`.
typedef LeaderboardFetch = Future<HunterLeaderboardPage> Function({
  int limit,
  String? cursor,
});

/// The one hunter ranking in the app, as the server orders it.
///
/// Gems also uses it to name the hunter behind a gem's `ownerReliability`
/// when that hunter is not the project's admin.
class HunterLeaderboardStore extends ChangeNotifier {
  HunterLeaderboardStore({LeaderboardFetch? fetch}) : _fetch = fetch;

  LeaderboardFetch? _fetch;

  LeaderboardFetch get _reader =>
      _fetch ??= HunterReliabilityApiRepository().fetchLeaderboard;

  /// The server's maximum page.
  static const int pageSize = 50;

  final List<HunterLeaderboardEntry> _entries = [];
  String? _nextCursor;
  bool _loaded = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  List<HunterLeaderboardEntry> get entries => List.unmodifiable(_entries);
  bool get hasLoaded => _loaded;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _nextCursor != null;
  String? get error => _error;

  /// Every loaded hunter by profile id.
  Map<String, HunterReliability> get byProfileId => {
        for (final e in _entries) e.reliability.profileId: e.reliability,
      };

  Future<void> loadOnce() async {
    if (_loaded || _isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final page = await _reader(limit: pageSize);
      _entries
        ..clear()
        ..addAll(page.entries);
      _nextCursor = page.nextCursor;
      _error = null;
      _loaded = true;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _isLoadingMore || _isLoading) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final page = await _reader(limit: pageSize, cursor: cursor);
      _entries.addAll(page.entries);
      _nextCursor = page.nextCursor;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
