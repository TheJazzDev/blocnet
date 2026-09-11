import 'dart:convert';

import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/core/home_bootstrap_payload.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:blocnet/services/core/home_bootstrap_payload.dart';

/// Fetches `GET /me/home-bootstrap` and mirrors the last good payload in
/// SharedPreferences so the Home tab can paint before the network answers.
///
/// Reads are stale-while-revalidate: a payload past the server's TTL is
/// still returned (flagged `isFresh: false`) up to [_maxStaleAge], because a
/// day-old feed beats a spinner. The cache is scoped to the user it was
/// written for so one account never sees another's feed after a sign-out.
class HomeBootstrapService {
  HomeBootstrapService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static const String _cacheKey = 'blocnet_home_bootstrap_cache_v1';
  static const String _cachedAtKey = 'blocnet_home_bootstrap_cached_at_v1';
  static const String _cacheUserKey = 'blocnet_home_bootstrap_user_v1';
  static const String _cacheVersionKey =
      'blocnet_home_bootstrap_cache_version_v1';

  /// v2: feed items are stored as raw API JSON (keeps `project`/`admin`).
  static const int _cacheVersion = 2;
  static const int _defaultTtlSec = 45;
  static const int _minTtlSec = 15;
  static const int _maxTtlSec = 15 * 60;
  static const Duration _maxStaleAge = Duration(days: 3);

  final ApiClient _apiClient;

  Future<HomeBootstrapPayload?> fetchHomeBootstrap({
    int feedLimit = 80,
    int windowDays = 7,
  }) async {
    final response = await _apiClient.get(
      '/me/home-bootstrap',
      query: {
        'feedLimit': '$feedLimit',
        'windowDays': '$windowDays',
      },
    );
    if (response is! Map<String, dynamic>) return null;
    return HomeBootstrapPayload.fromApi(response);
  }

  /// Returns the cached payload, fresh or stale, or null when there is none
  /// (or it is older than [_maxStaleAge] / written by an older format).
  Future<CachedHomeBootstrap?> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_cacheVersionKey) != _cacheVersion) return null;

    final raw = prefs.getString(_cacheKey);
    final cachedAtRaw = prefs.getString(_cachedAtKey);
    if (raw == null || cachedAtRaw == null) return null;

    final cachedAt = DateTime.tryParse(cachedAtRaw);
    if (cachedAt == null) return null;

    final age = DateTime.now().difference(cachedAt);
    if (age > _maxStaleAge) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final payload = HomeBootstrapPayload.fromCacheJson(decoded);

    final ttlSec = payload.cacheTtlSec <= 0
        ? _defaultTtlSec
        : payload.cacheTtlSec.clamp(_minTtlSec, _maxTtlSec);

    return CachedHomeBootstrap(
      payload: payload,
      userId: prefs.getString(_cacheUserKey),
      cachedAt: cachedAt,
      isFresh: age.inSeconds <= ttlSec,
    );
  }

  Future<void> saveCached(HomeBootstrapPayload payload, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(payload.toCacheJson()));
    await prefs.setString(_cachedAtKey, DateTime.now().toIso8601String());
    await prefs.setInt(_cacheVersionKey, _cacheVersion);
    if (userId == null || userId.isEmpty) {
      await prefs.remove(_cacheUserKey);
    } else {
      await prefs.setString(_cacheUserKey, userId);
    }
  }
}
