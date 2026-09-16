/// `GET /mining/leaderboard` rows and the member's own `me` row.
library;

import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/shared/utils/user_level_parsing.dart';

class MiningLeaderboardEntry {
  const MiningLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    this.primaryBadge,
    this.currentLevel,
    required this.claimedTotalPoints,
    required this.maturedUnclaimedPoints,
    required this.lifetimeEarnedPoints,
    required this.sessionStatus,
    required this.sessionProgressPct,
    required this.sessionEndsAt,
    required this.boostBpsSnapshot,
    required this.activeReferralsSnapshot,
    bool? isMiningNow,
  }) : _isMiningNow = isMiningNow;

  final int rank;
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final dynamic primaryBadge;
  final UserLevelModel? currentLevel;
  final int claimedTotalPoints;
  final int maturedUnclaimedPoints;
  final int lifetimeEarnedPoints;
  final String sessionStatus;
  final double sessionProgressPct;
  final DateTime? sessionEndsAt;
  final int boostBpsSnapshot;
  final int activeReferralsSnapshot;

  /// Sent on the `me` block only; rows derive it from [sessionStatus].
  final bool? _isMiningNow;

  bool get isMiningNow => _isMiningNow ?? sessionStatus == 'running';

  factory MiningLeaderboardEntry.fromApi(Map<String, dynamic> json) {
    dynamic primaryBadge;
    final badgeData = json['primaryBadge'];
    if (badgeData != null && badgeData is Map<String, dynamic>) {
      try {
        // Import BadgeModel if needed
        primaryBadge = badgeData;
      } catch (_) {
        primaryBadge = null;
      }
    }

    return MiningLeaderboardEntry(
      rank: int.tryParse(json['rank']?.toString() ?? '') ?? 0,
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString(),
      displayName: json['displayName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      primaryBadge: primaryBadge,
      currentLevel: parseCurrentLevel(json['currentLevel']),
      claimedTotalPoints:
          int.tryParse(json['claimedTotalPoints']?.toString() ?? '') ?? 0,
      maturedUnclaimedPoints:
          int.tryParse(json['maturedUnclaimedPoints']?.toString() ?? '') ?? 0,
      lifetimeEarnedPoints:
          int.tryParse(json['lifetimeEarnedPoints']?.toString() ?? '') ?? 0,
      sessionStatus: json['sessionStatus']?.toString() ?? 'idle',
      sessionProgressPct:
          double.tryParse(json['sessionProgressPct']?.toString() ?? '') ?? 0,
      sessionEndsAt: DateTime.tryParse(json['sessionEndsAt']?.toString() ?? ''),
      boostBpsSnapshot:
          int.tryParse(json['boostBpsSnapshot']?.toString() ?? '') ?? 0,
      activeReferralsSnapshot:
          int.tryParse(json['activeReferralsSnapshot']?.toString() ?? '') ?? 0,
      isMiningNow:
          json['isMiningNow'] is bool ? json['isMiningNow'] as bool : null,
    );
  }
}

class MiningLeaderboardResponse {
  const MiningLeaderboardResponse({
    required this.data,
    required this.total,
    required this.limit,
    required this.offset,
    this.me,
  });

  final List<MiningLeaderboardEntry> data;

  /// The signed-in member's own row, or null when they are not ranked (or an
  /// older backend does not send it).
  final MiningLeaderboardEntry? me;
  final int total;
  final int limit;
  final int offset;

  factory MiningLeaderboardResponse.fromApi(Map<String, dynamic> json) {
    final rows = (json['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MiningLeaderboardEntry.fromApi)
        .toList();

    return MiningLeaderboardResponse(
      data: rows,
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      limit: int.tryParse(json['limit']?.toString() ?? '') ?? rows.length,
      offset: int.tryParse(json['offset']?.toString() ?? '') ?? 0,
      me: json['me'] is Map<String, dynamic>
          ? MiningLeaderboardEntry.fromApi(json['me'] as Map<String, dynamic>)
          : null,
    );
  }
}
