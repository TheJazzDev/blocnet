/// Shared `GET /mining/me` bodies for mining tests.
library;

final DateTime miningAsOf = DateTime.utc(2026, 9, 16, 12);

Map<String, dynamic> idleSessionJson() => <String, dynamic>{
      'id': null,
      'status': 'idle',
      'progressPct': 0,
      'pointsMinedSoFar': 0,
      'effectivePointsPerCycle': 120,
      'hourlyRateNow': 5,
      'cycleHours': 24,
      'projectedCyclePointsNow': 120,
    };

/// A live cycle as the backend sends it: no `cycleHours`.
Map<String, dynamic> runningSessionJson({
  String id = 'session-1',
  String status = 'running',
  DateTime? endsAt,
}) {
  final end = endsAt ?? miningAsOf.add(const Duration(hours: 1));
  return <String, dynamic>{
    'id': id,
    'status': status,
    'startsAt': end.subtract(const Duration(hours: 24)).toIso8601String(),
    'endsAt': end.toIso8601String(),
    'progressPct': status == 'claimable' ? 1 : 0.5,
    'pointsMinedSoFar': 60,
    'effectivePointsPerCycle': 120,
    'hourlyRateNow': 5,
    'currentHourEstimatedPoints': 0,
    'projectedCyclePointsNow': 120,
  };
}

Map<String, dynamic> miningSnapshotJson({
  Map<String, dynamic>? session,
  bool enabled = true,
  int cycleHours = 24,
  Map<String, dynamic>? lastExpiredCycle,
}) {
  return <String, dynamic>{
    'asOf': miningAsOf.toIso8601String(),
    'config': {
      'enabled': enabled,
      'referralsEnabled': true,
      'cycleHours': cycleHours,
      'basePointsPerCycle': 120,
      'perActiveReferralBoostBps': 500,
      'maxBoostBps': 10000,
      'activeReferralWindowHours': 168,
      'referralBindWindowHours': 24,
      'claimWindowHours': 48,
    },
    'balance': {
      'claimedTotalPoints': '360',
      'maturedUnclaimedPoints': 0,
      'lifetimeEarnedPoints': '420',
    },
    'session': session ?? idleSessionJson(),
    'referral': {'code': 'AB12CD34', 'activeDirectReferrals': 0},
    'hourlyHistory': const <dynamic>[],
    'lastExpiredCycle': lastExpiredCycle,
  };
}
