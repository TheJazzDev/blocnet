import 'dart:convert';

import 'package:blocnet/features/engagement/data/models/edge_brief_model.dart';
import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeBootstrapPayload {
  const HomeBootstrapPayload({
    required this.asOf,
    required this.partial,
    required this.cacheTtlSec,
    required this.feedItems,
    required this.meSummary,
    required this.edgeBrief,
    required this.radar,
    required this.unreadCount,
  });

  final DateTime asOf;
  final bool partial;
  final int cacheTtlSec;
  final List<Update> feedItems;
  final Map<String, dynamic>? meSummary;
  final EdgeBriefResponse? edgeBrief;
  final RadarSummary? radar;
  final int unreadCount;

  factory HomeBootstrapPayload.fromApi(Map<String, dynamic> json) {
    final feed = json['feed'] as Map<String, dynamic>?;
    final rawItems = feed?['items'] as List<dynamic>? ?? const [];
    final feedItems = rawItems
        .whereType<Map<String, dynamic>>()
        .map(Update.fromApi)
        .toList(growable: false);

    final meSummary = json['meSummary'] is Map<String, dynamic>
        ? json['meSummary'] as Map<String, dynamic>
        : null;

    final edgeBriefMap = json['edgeBrief'];
    final radarMap = json['radar'];
    final notifications = json['notifications'] as Map<String, dynamic>?;

    return HomeBootstrapPayload(
      asOf:
          DateTime.tryParse((json['asOf'] ?? '').toString()) ?? DateTime.now(),
      partial: json['partial'] == true,
      cacheTtlSec: int.tryParse((json['cacheTtlSec'] ?? '').toString()) ?? 45,
      feedItems: feedItems,
      meSummary: meSummary,
      edgeBrief: edgeBriefMap is Map<String, dynamic>
          ? EdgeBriefResponse.fromApi(edgeBriefMap)
          : null,
      radar: radarMap is Map<String, dynamic>
          ? RadarSummary.fromApi(radarMap)
          : null,
      unreadCount:
          int.tryParse((notifications?['unreadCount'] ?? '').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'asOf': asOf.toIso8601String(),
      'partial': partial,
      'cacheTtlSec': cacheTtlSec,
      'feedItems': feedItems.map((item) => item.toJson()).toList(),
      'meSummary': meSummary,
      'edgeBrief': edgeBrief?.toJson(),
      'radar': radar?.toJson(),
      'unreadCount': unreadCount,
    };
  }

  factory HomeBootstrapPayload.fromCacheJson(Map<String, dynamic> json) {
    final rawItems = json['feedItems'] as List<dynamic>? ?? const [];
    final feedItems = rawItems
        .whereType<Map<String, dynamic>>()
        .map(Update.fromApi)
        .toList(growable: false);

    final meSummary = json['meSummary'] is Map<String, dynamic>
        ? json['meSummary'] as Map<String, dynamic>
        : null;

    final edgeBriefMap = json['edgeBrief'];
    final radarMap = json['radar'];

    return HomeBootstrapPayload(
      asOf:
          DateTime.tryParse((json['asOf'] ?? '').toString()) ?? DateTime.now(),
      partial: json['partial'] == true,
      cacheTtlSec: int.tryParse((json['cacheTtlSec'] ?? '').toString()) ?? 45,
      feedItems: feedItems,
      meSummary: meSummary,
      edgeBrief: edgeBriefMap is Map<String, dynamic>
          ? EdgeBriefResponse.fromApi(edgeBriefMap)
          : null,
      radar: radarMap is Map<String, dynamic>
          ? RadarSummary.fromApi(radarMap)
          : null,
      unreadCount: int.tryParse((json['unreadCount'] ?? '').toString()) ?? 0,
    );
  }
}

class HomeBootstrapService {
  HomeBootstrapService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static const String _cacheKey = 'blocnet_home_bootstrap_cache_v1';
  static const String _cachedAtKey = 'blocnet_home_bootstrap_cached_at_v1';
  static const String _cacheVersionKey =
      'blocnet_home_bootstrap_cache_version_v1';
  static const int _cacheVersion = 1;
  static const int _defaultTtlSec = 45;
  static const int _minTtlSec = 15;
  static const int _maxTtlSec = 15 * 60;

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

  Future<HomeBootstrapPayload?> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_cacheVersionKey) != _cacheVersion) {
      return null;
    }

    final raw = prefs.getString(_cacheKey);
    final cachedAtRaw = prefs.getString(_cachedAtKey);
    if (raw == null || cachedAtRaw == null) return null;

    final cachedAt = DateTime.tryParse(cachedAtRaw);
    if (cachedAt == null) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final payload = HomeBootstrapPayload.fromCacheJson(decoded);
    final age = DateTime.now().difference(cachedAt);
    final ttlSec = payload.cacheTtlSec <= 0
        ? _defaultTtlSec
        : payload.cacheTtlSec.clamp(_minTtlSec, _maxTtlSec);

    if (age.inSeconds > ttlSec) return null;
    return payload;
  }

  Future<void> saveCached(HomeBootstrapPayload payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(payload.toCacheJson()));
    await prefs.setString(_cachedAtKey, DateTime.now().toIso8601String());
    await prefs.setInt(_cacheVersionKey, _cacheVersion);
  }
}
