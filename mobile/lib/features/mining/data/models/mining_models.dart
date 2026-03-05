class MiningConfigModel {
  const MiningConfigModel({
    required this.cycleHours,
    required this.basePointsPerCycle,
    required this.perActiveReferralBoostBps,
    required this.maxBoostBps,
    required this.activeReferralWindowHours,
    required this.referralBindWindowHours,
    required this.enabled,
    required this.referralsEnabled,
  });

  final int cycleHours;
  final int basePointsPerCycle;
  final int perActiveReferralBoostBps;
  final int maxBoostBps;
  final int activeReferralWindowHours;
  final int referralBindWindowHours;
  final bool enabled;
  final bool referralsEnabled;

  factory MiningConfigModel.fromApi(Map<String, dynamic> json) {
    return MiningConfigModel(
      cycleHours: int.tryParse(json['cycleHours']?.toString() ?? '') ?? 24,
      basePointsPerCycle:
          int.tryParse(json['basePointsPerCycle']?.toString() ?? '') ?? 120,
      perActiveReferralBoostBps:
          int.tryParse(json['perActiveReferralBoostBps']?.toString() ?? '') ??
              500,
      maxBoostBps: int.tryParse(json['maxBoostBps']?.toString() ?? '') ?? 10000,
      activeReferralWindowHours:
          int.tryParse(json['activeReferralWindowHours']?.toString() ?? '') ??
              168,
      referralBindWindowHours:
          int.tryParse(json['referralBindWindowHours']?.toString() ?? '') ?? 24,
      enabled: json['enabled'] == true,
      referralsEnabled: json['referralsEnabled'] == true,
    );
  }
}

class MiningBalanceModel {
  const MiningBalanceModel({
    required this.claimedTotalPoints,
    required this.maturedUnclaimedPoints,
    required this.lifetimeEarnedPoints,
  });

  final int claimedTotalPoints;
  final int maturedUnclaimedPoints;
  final int lifetimeEarnedPoints;

  factory MiningBalanceModel.fromApi(Map<String, dynamic> json) {
    return MiningBalanceModel(
      claimedTotalPoints:
          int.tryParse(json['claimedTotalPoints']?.toString() ?? '') ?? 0,
      maturedUnclaimedPoints:
          int.tryParse(json['maturedUnclaimedPoints']?.toString() ?? '') ?? 0,
      lifetimeEarnedPoints:
          int.tryParse(json['lifetimeEarnedPoints']?.toString() ?? '') ?? 0,
    );
  }
}

class MiningSessionModel {
  const MiningSessionModel({
    required this.id,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.progressPct,
    required this.pointsMinedSoFar,
    required this.effectivePointsPerCycle,
    required this.boostBpsSnapshot,
    required this.activeReferralsSnapshot,
    required this.hourlyRateNow,
    required this.currentHourEstimatedPoints,
    required this.completedHours,
    required this.cycleHours,
    required this.projectedCyclePointsNow,
  });

  final String? id;
  final String status;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final double progressPct;
  final int pointsMinedSoFar;
  final int effectivePointsPerCycle;
  final int boostBpsSnapshot;
  final int activeReferralsSnapshot;
  final double hourlyRateNow;
  final double currentHourEstimatedPoints;
  final int completedHours;
  final int cycleHours;
  final int projectedCyclePointsNow;

  bool get isIdle => status == 'idle';
  bool get isRunning => status == 'running';
  bool get isClaimable => status == 'claimable';

  factory MiningSessionModel.fromApi(Map<String, dynamic> json) {
    return MiningSessionModel(
      id: json['id']?.toString(),
      status: json['status']?.toString() ?? 'idle',
      startsAt: DateTime.tryParse(json['startsAt']?.toString() ?? ''),
      endsAt: DateTime.tryParse(json['endsAt']?.toString() ?? ''),
      progressPct: double.tryParse(json['progressPct']?.toString() ?? '') ?? 0,
      pointsMinedSoFar:
          int.tryParse(json['pointsMinedSoFar']?.toString() ?? '') ?? 0,
      effectivePointsPerCycle:
          int.tryParse(json['effectivePointsPerCycle']?.toString() ?? '') ?? 0,
      boostBpsSnapshot:
          int.tryParse(json['boostBpsSnapshot']?.toString() ?? '') ?? 0,
      activeReferralsSnapshot:
          int.tryParse(json['activeReferralsSnapshot']?.toString() ?? '') ?? 0,
      hourlyRateNow:
          double.tryParse(json['hourlyRateNow']?.toString() ?? '') ?? 0,
      currentHourEstimatedPoints: double.tryParse(
              json['currentHourEstimatedPoints']?.toString() ?? '') ??
          0,
      completedHours:
          int.tryParse(json['completedHours']?.toString() ?? '') ?? 0,
      cycleHours: int.tryParse(json['cycleHours']?.toString() ?? '') ?? 24,
      projectedCyclePointsNow:
          int.tryParse(json['projectedCyclePointsNow']?.toString() ?? '') ??
              int.tryParse(json['effectivePointsPerCycle']?.toString() ?? '') ??
              0,
    );
  }
}

class ReferrerSummary {
  const ReferrerSummary({
    required this.id,
    required this.username,
    required this.displayName,
    required this.code,
  });

  final String id;
  final String? username;
  final String? displayName;
  final String? code;

  factory ReferrerSummary.fromApi(Map<String, dynamic> json) {
    return ReferrerSummary(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString(),
      displayName: json['displayName']?.toString(),
      code: json['code']?.toString() ?? json['referralCode']?.toString(),
    );
  }
}

class ReferralSummaryModel {
  const ReferralSummaryModel({
    required this.code,
    required this.referredBy,
    required this.canBindUntil,
    required this.bindWindowOpen,
    required this.activeDirectReferrals,
    required this.totalDirectReferrals,
  });

  final String? code;
  final ReferrerSummary? referredBy;
  final DateTime? canBindUntil;
  final bool bindWindowOpen;
  final int activeDirectReferrals;
  final int totalDirectReferrals;

  bool get isBound => referredBy != null;

  factory ReferralSummaryModel.fromApi(Map<String, dynamic> json) {
    final referredByRaw = json['referredBy'];
    return ReferralSummaryModel(
      code: json['code']?.toString(),
      referredBy: referredByRaw is Map<String, dynamic>
          ? ReferrerSummary.fromApi(referredByRaw)
          : null,
      canBindUntil: DateTime.tryParse(json['canBindUntil']?.toString() ?? ''),
      bindWindowOpen: json['bindWindowOpen'] == true,
      activeDirectReferrals:
          int.tryParse(json['activeDirectReferrals']?.toString() ?? '') ?? 0,
      totalDirectReferrals:
          int.tryParse(json['totalDirectReferrals']?.toString() ?? '') ?? 0,
    );
  }
}

class MiningHourlyCheckpointModel {
  const MiningHourlyCheckpointModel({
    required this.id,
    required this.sessionId,
    required this.hourIndex,
    required this.hourStartAt,
    required this.hourEndAt,
    required this.points,
    required this.activeReferralsSnapshot,
    required this.boostBpsSnapshot,
    required this.claimedAt,
    required this.status,
  });

  final String id;
  final String sessionId;
  final int hourIndex;
  final DateTime? hourStartAt;
  final DateTime? hourEndAt;
  final double points;
  final int activeReferralsSnapshot;
  final int boostBpsSnapshot;
  final DateTime? claimedAt;
  final String status;

  bool get isClaimed => status == 'claimed';

  factory MiningHourlyCheckpointModel.fromApi(Map<String, dynamic> json) {
    return MiningHourlyCheckpointModel(
      id: json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      hourIndex: int.tryParse(json['hourIndex']?.toString() ?? '') ?? 0,
      hourStartAt: DateTime.tryParse(json['hourStartAt']?.toString() ?? ''),
      hourEndAt: DateTime.tryParse(json['hourEndAt']?.toString() ?? ''),
      points: double.tryParse(json['points']?.toString() ?? '') ?? 0,
      activeReferralsSnapshot:
          int.tryParse(json['activeReferralsSnapshot']?.toString() ?? '') ?? 0,
      boostBpsSnapshot:
          int.tryParse(json['boostBpsSnapshot']?.toString() ?? '') ?? 0,
      claimedAt: DateTime.tryParse(json['claimedAt']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'unclaimed',
    );
  }
}

class MiningSnapshot {
  const MiningSnapshot({
    required this.asOf,
    required this.config,
    required this.balance,
    required this.session,
    required this.referral,
    required this.hourlyHistory,
  });

  final DateTime asOf;
  final MiningConfigModel config;
  final MiningBalanceModel balance;
  final MiningSessionModel session;
  final ReferralSummaryModel referral;
  final List<MiningHourlyCheckpointModel> hourlyHistory;

  factory MiningSnapshot.fromApi(Map<String, dynamic> json) {
    final configRaw = (json['config'] as Map?)?.cast<String, dynamic>() ?? {};
    final balanceRaw = (json['balance'] as Map?)?.cast<String, dynamic>() ?? {};
    final sessionRaw = (json['session'] as Map?)?.cast<String, dynamic>() ?? {};
    final referralRaw =
        (json['referral'] as Map?)?.cast<String, dynamic>() ?? {};
    final hourlyHistoryRaw =
        (json['hourlyHistory'] as List?)?.cast<dynamic>() ?? const [];

    return MiningSnapshot(
      asOf: DateTime.tryParse(json['asOf']?.toString() ?? '') ?? DateTime.now(),
      config: MiningConfigModel.fromApi(configRaw),
      balance: MiningBalanceModel.fromApi(balanceRaw),
      session: MiningSessionModel.fromApi(sessionRaw),
      referral: ReferralSummaryModel.fromApi(referralRaw),
      hourlyHistory: hourlyHistoryRaw
          .whereType<Map>()
          .map(
            (row) => MiningHourlyCheckpointModel.fromApi(
              row.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
    );
  }
}

class DownlineMember {
  const DownlineMember({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.status,
    required this.isActive,
    required this.progressPct,
    required this.claimedTotalPoints,
    required this.referredAt,
    required this.lastActiveAt,
  });

  final String id;
  final String? email;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String status;
  final bool isActive;
  final double progressPct;
  final int claimedTotalPoints;
  final DateTime? referredAt;
  final DateTime? lastActiveAt;

  factory DownlineMember.fromApi(Map<String, dynamic> json) {
    return DownlineMember(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      username: json['username']?.toString(),
      displayName: json['displayName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      status: json['status']?.toString() ?? 'idle',
      isActive: json['isActive'] == true,
      progressPct: double.tryParse(json['progressPct']?.toString() ?? '') ?? 0,
      claimedTotalPoints:
          int.tryParse(json['claimedTotalPoints']?.toString() ?? '') ?? 0,
      referredAt: DateTime.tryParse(json['referredAt']?.toString() ?? ''),
      lastActiveAt: DateTime.tryParse(json['lastActiveAt']?.toString() ?? ''),
    );
  }
}

class DownlineResponse {
  const DownlineResponse({
    required this.data,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<DownlineMember> data;
  final int total;
  final int limit;
  final int offset;

  factory DownlineResponse.fromApi(Map<String, dynamic> json) {
    final rows = (json['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DownlineMember.fromApi)
        .toList();

    return DownlineResponse(
      data: rows,
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      limit: int.tryParse(json['limit']?.toString() ?? '') ?? rows.length,
      offset: int.tryParse(json['offset']?.toString() ?? '') ?? 0,
    );
  }
}

class MiningLeaderboardEntry {
  const MiningLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    this.primaryBadge,
    required this.claimedTotalPoints,
    required this.maturedUnclaimedPoints,
    required this.lifetimeEarnedPoints,
    required this.sessionStatus,
    required this.sessionProgressPct,
    required this.sessionEndsAt,
    required this.boostBpsSnapshot,
    required this.activeReferralsSnapshot,
  });

  final int rank;
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final dynamic primaryBadge;
  final int claimedTotalPoints;
  final int maturedUnclaimedPoints;
  final int lifetimeEarnedPoints;
  final String sessionStatus;
  final double sessionProgressPct;
  final DateTime? sessionEndsAt;
  final int boostBpsSnapshot;
  final int activeReferralsSnapshot;

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
    );
  }
}

class MiningLeaderboardResponse {
  const MiningLeaderboardResponse({
    required this.data,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<MiningLeaderboardEntry> data;
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
    );
  }
}

class ReferralValidation {
  const ReferralValidation({
    required this.valid,
    required this.code,
    required this.referrerName,
  });

  final bool valid;
  final String code;
  final String? referrerName;

  factory ReferralValidation.fromApi(Map<String, dynamic> json) {
    final referrer = (json['referrer'] as Map?)?.cast<String, dynamic>();
    return ReferralValidation(
      valid: json['valid'] == true,
      code: json['code']?.toString() ?? '',
      referrerName: referrer?['displayName']?.toString(),
    );
  }
}
