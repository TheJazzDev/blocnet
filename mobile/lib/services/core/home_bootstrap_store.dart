import 'package:blocnet/services/core/home_bootstrap_service.dart';
import 'package:blocnet/services/users/me_snapshot_cache.dart';
import 'package:flutter/foundation.dart';

/// Owns the Home bootstrap payload across the app's lifetime.
///
/// Created eagerly in `main.dart` so [warmUp] has read the on-disk cache
/// long before the Home tab is built. The Home screen then paints
/// [cachedFor] synchronously in `initState` (first frame, no spinner) and
/// calls [fetchRemote] to replace it with fresh data.
class HomeBootstrapStore extends ChangeNotifier {
  HomeBootstrapStore({HomeBootstrapService? service})
      : _service = service ?? HomeBootstrapService();

  final HomeBootstrapService _service;

  CachedHomeBootstrap? _cached;
  HomeBootstrapPayload? _latest;
  Future<void>? _warmUp;
  bool _warmUpDone = false;
  bool _isFetching = false;
  String? _lastError;

  /// The most recent payload applied, remote or cached.
  HomeBootstrapPayload? get latest => _latest;

  /// True once the on-disk cache has been read (hit or miss).
  bool get hasWarmedUp => _warmUpDone;
  bool get isFetching => _isFetching;
  String? get lastError => _lastError;

  /// Cached payload for [userId], or null when the cache belongs to someone
  /// else (or has not been read yet). A cache written before user scoping
  /// existed (no user id) is treated as belonging to the current user.
  HomeBootstrapPayload? cachedFor(String? userId) {
    final cached = _cached;
    if (cached == null) return null;
    final owner = cached.userId;
    if (owner != null && userId != null && owner != userId) return null;
    return cached.payload;
  }

  bool get isCacheFresh => _cached?.isFresh ?? false;

  /// Reads the on-disk cache once. Safe to call repeatedly; later calls
  /// await the first read.
  Future<void> warmUp() {
    return _warmUp ??= _readCache();
  }

  Future<void> _readCache() async {
    try {
      _cached = await _service.loadCached();
    } catch (_) {
      _cached = null;
    } finally {
      _warmUpDone = true;
      notifyListeners();
    }
  }

  /// Fetches a fresh payload, persists it for [userId] and returns it.
  /// Returns null on failure and leaves [latest] untouched.
  Future<HomeBootstrapPayload?> fetchRemote({
    required String? userId,
    int feedLimit = 100,
    int windowDays = 7,
  }) async {
    if (_isFetching) return null;
    _isFetching = true;
    _lastError = null;
    notifyListeners();

    try {
      final payload = await _service.fetchHomeBootstrap(
        feedLimit: feedLimit,
        windowDays: windowDays,
      );
      if (payload == null) return null;
      // `meSummary` is the `/me` document verbatim (the handler calls
      // `UsersService.getMe`), so publish it and spare the other stores a
      // second request. Only network payloads qualify: the on-disk cache can
      // be days old.
      MeSnapshotCache.write(payload.meSummary);
      _latest = payload;
      _cached = CachedHomeBootstrap(
        payload: payload,
        userId: userId,
        cachedAt: DateTime.now(),
        isFresh: true,
      );
      await _service.saveCached(payload, userId: userId);
      return payload;
    } catch (error) {
      _lastError = error.toString();
      return null;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Marks a cached payload as applied so [latest] reflects what is on
  /// screen even before the network answers.
  void markApplied(HomeBootstrapPayload payload) {
    _latest = payload;
  }
}
