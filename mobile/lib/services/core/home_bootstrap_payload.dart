import 'package:blocnet/features/engagement/data/models/edge_brief_model.dart';
import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';

/// One `GET /me/home-bootstrap` response, parsed once and reusable both for
/// the live screen and for the on-disk cache.
///
/// The feed is kept twice on purpose: [feedItems] is the parsed list the
/// stores consume, [rawFeedItems] is the untouched API JSON that gets
/// persisted. `Update.toJson()` drops the nested `project` and `admin`
/// objects, and the Home feed only renders rows that have both, so caching
/// the parsed form would leave the cached feed permanently empty.
class HomeBootstrapPayload {
  const HomeBootstrapPayload({
    required this.asOf,
    required this.partial,
    required this.cacheTtlSec,
    required this.feedItems,
    required this.rawFeedItems,
    required this.meSummary,
    required this.edgeBrief,
    required this.radar,
    required this.unreadCount,
  });

  final DateTime asOf;
  final bool partial;
  final int cacheTtlSec;
  final List<Update> feedItems;
  final List<Map<String, dynamic>> rawFeedItems;
  final Map<String, dynamic>? meSummary;
  final EdgeBriefResponse? edgeBrief;
  final RadarSummary? radar;
  final int unreadCount;

  bool get hasFeed => feedItems.isNotEmpty;
  bool get hasEdgeBrief => edgeBrief != null;
  bool get hasRadar => radar != null;

  factory HomeBootstrapPayload.fromApi(Map<String, dynamic> json) {
    final feed = json['feed'] as Map<String, dynamic>?;
    final notifications = json['notifications'] as Map<String, dynamic>?;
    return _build(
      json,
      rawItems: feed?['items'],
      unreadCount: notifications?['unreadCount'],
    );
  }

  factory HomeBootstrapPayload.fromCacheJson(Map<String, dynamic> json) {
    return _build(
      json,
      rawItems: json['feedItems'],
      unreadCount: json['unreadCount'],
    );
  }

  static HomeBootstrapPayload _build(
    Map<String, dynamic> json, {
    required Object? rawItems,
    required Object? unreadCount,
  }) {
    final rawFeedItems = (rawItems as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final edgeBriefMap = json['edgeBrief'];
    final radarMap = json['radar'];

    return HomeBootstrapPayload(
      asOf:
          DateTime.tryParse((json['asOf'] ?? '').toString()) ?? DateTime.now(),
      partial: json['partial'] == true,
      cacheTtlSec: int.tryParse((json['cacheTtlSec'] ?? '').toString()) ?? 45,
      feedItems: rawFeedItems.map(Update.fromApi).toList(growable: false),
      rawFeedItems: rawFeedItems,
      meSummary: json['meSummary'] is Map<String, dynamic>
          ? json['meSummary'] as Map<String, dynamic>
          : null,
      edgeBrief: edgeBriefMap is Map<String, dynamic>
          ? EdgeBriefResponse.fromApi(edgeBriefMap)
          : null,
      radar: radarMap is Map<String, dynamic>
          ? RadarSummary.fromApi(radarMap)
          : null,
      unreadCount: int.tryParse((unreadCount ?? '').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'asOf': asOf.toIso8601String(),
      'partial': partial,
      'cacheTtlSec': cacheTtlSec,
      'feedItems': rawFeedItems,
      'meSummary': meSummary,
      'edgeBrief': edgeBrief?.toJson(),
      'radar': radar?.toJson(),
      'unreadCount': unreadCount,
    };
  }
}

/// A payload read back from disk, tagged with whether it is still inside the
/// server's suggested TTL. Stale payloads are still worth painting on the
/// first frame; the caller just refreshes behind them.
class CachedHomeBootstrap {
  const CachedHomeBootstrap({
    required this.payload,
    required this.userId,
    required this.cachedAt,
    required this.isFresh,
  });

  final HomeBootstrapPayload payload;
  final String? userId;
  final DateTime cachedAt;
  final bool isFresh;
}
