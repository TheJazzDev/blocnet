import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/hunter/data/models/reliability_json.dart';

class HunterLeaderboardEntry {
  const HunterLeaderboardEntry({required this.rank, required this.reliability});

  /// 1-based position in the full ranking.
  final int rank;
  final HunterReliability reliability;

  factory HunterLeaderboardEntry.fromApi(Map<String, dynamic> json) {
    return HunterLeaderboardEntry(
      rank: jsonInt(json['rank']),
      reliability: HunterReliability.fromApi(json),
    );
  }
}

/// One page of `GET /hunters/leaderboard`. The order is the server's ranking.
class HunterLeaderboardPage {
  const HunterLeaderboardPage({required this.entries, this.nextCursor});

  final List<HunterLeaderboardEntry> entries;

  /// Pass back as `cursor` for the next page; null on the last page.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  factory HunterLeaderboardPage.fromApi(Map<String, dynamic> json) {
    return HunterLeaderboardPage(
      entries: jsonMapList(json['items'])
          .map(HunterLeaderboardEntry.fromApi)
          .toList(growable: false),
      nextCursor: jsonStringOrNull(json['nextCursor']),
    );
  }
}
