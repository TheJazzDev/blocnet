/// Mine tab bodies built around the design's own examples. Times are local
/// (no `Z`) so the copy the tests expect does not depend on the machine's
/// time zone.
library;

import 'package:blocnet/features/mining/data/models/mining_models.dart';

String iso(DateTime time) => time.toIso8601String();

/// State 2: Wed 16 Sep, 18:20 — nine hours into a cycle that started 09:20.
final DateTime runningNow = DateTime(2026, 9, 16, 18, 20);
final DateTime runningStart = DateTime(2026, 9, 16, 9, 20);

/// State 3: Thu 17 Sep 09:20, 30 hours before a Fri 15:20 deadline.
final DateTime readyNow = DateTime(2026, 9, 17, 9, 20);

/// State 4: Fri 18 Sep 12:20, three hours before the same deadline.
final DateTime soonNow = DateTime(2026, 9, 18, 12, 20);

/// Cycle that ended Wed 16 Sep 15:20; with a 48 h window it expires Fri 15:20.
final DateTime claimableEnd = DateTime(2026, 9, 16, 15, 20);

Map<String, dynamic> idleSession() => <String, dynamic>{
      'id': null,
      'status': 'idle',
      'progressPct': 0,
      'pointsMinedSoFar': 0,
      'effectivePointsPerCycle': 120,
      'hourlyRateNow': 5,
      'cycleHours': 24,
    };

Map<String, dynamic> runningSession({
  String id = 'run-1',
  DateTime? startsAt,
  int mined = 49,
  int perCycle = 132,
  int boostBps = 1000,
  int activeFriends = 2,
}) {
  final start = startsAt ?? runningStart;
  return <String, dynamic>{
    'id': id,
    'status': 'running',
    'startsAt': iso(start),
    'endsAt': iso(start.add(const Duration(hours: 24))),
    'progressPct': 0.375,
    'pointsMinedSoFar': mined,
    'effectivePointsPerCycle': perCycle,
    'boostBpsSnapshot': boostBps,
    'activeReferralsSnapshot': activeFriends,
    'hourlyRateNow': 5.5,
    'currentHourEstimatedPoints': 0,
  };
}

Map<String, dynamic> claimableSession({int points = 132}) => <String, dynamic>{
      'id': 'ready-1',
      'status': 'claimable',
      'startsAt': iso(claimableEnd.subtract(const Duration(hours: 24))),
      'endsAt': iso(claimableEnd),
      'progressPct': 1,
      'pointsMinedSoFar': points,
      'effectivePointsPerCycle': points,
      'boostBpsSnapshot': 1000,
      'activeReferralsSnapshot': 2,
      'hourlyRateNow': 5.5,
      'currentHourEstimatedPoints': 0,
    };

Map<String, dynamic> checkpoint({
  required String sessionId,
  required DateTime hourStart,
  String status = 'claimed',
  double points = 5.5,
}) =>
    <String, dynamic>{
      'id': '$sessionId-${hourStart.hour}',
      'sessionId': sessionId,
      'hourIndex': hourStart.hour,
      'hourStartAt': iso(hourStart),
      'hourEndAt': iso(hourStart.add(const Duration(hours: 1))),
      'points': points,
      'status': status,
      if (status == 'expired') 'expiredAt': iso(hourStart),
      if (status == 'claimed') 'claimedAt': iso(hourStart),
    };

Map<String, dynamic> mineSnapshotJson({
  DateTime? asOf,
  Map<String, dynamic>? session,
  bool enabled = true,
  bool referralsEnabled = true,
  int balance = 8412,
  int lifetime = 8412,
  int activeFriends = 0,
  String? code = 'BNC4K92X',
  List<Map<String, dynamic>> history = const [],
  Map<String, dynamic>? lastExpiredCycle,
}) {
  return <String, dynamic>{
    'asOf': iso(asOf ?? runningNow),
    'config': {
      'enabled': enabled,
      'referralsEnabled': referralsEnabled,
      'cycleHours': 24,
      'basePointsPerCycle': 120,
      'perActiveReferralBoostBps': 500,
      'maxBoostBps': 10000,
      'activeReferralWindowHours': 168,
      'referralBindWindowHours': 24,
      'claimWindowHours': 48,
    },
    'balance': {
      'claimedTotalPoints': '$balance',
      'maturedUnclaimedPoints': 0,
      'lifetimeEarnedPoints': '$lifetime',
    },
    'session': session ?? idleSession(),
    'referral': {
      'code': code,
      'activeDirectReferrals': activeFriends,
      'totalDirectReferrals': activeFriends,
    },
    'hourlyHistory': history,
    'lastExpiredCycle': lastExpiredCycle,
  };
}

MiningSnapshot mineSnapshot({
  DateTime? asOf,
  Map<String, dynamic>? session,
  bool enabled = true,
  int balance = 8412,
  int lifetime = 8412,
  int activeFriends = 0,
  List<Map<String, dynamic>> history = const [],
  Map<String, dynamic>? lastExpiredCycle,
}) {
  return MiningSnapshot.fromApi(
    mineSnapshotJson(
      asOf: asOf,
      session: session,
      enabled: enabled,
      balance: balance,
      lifetime: lifetime,
      activeFriends: activeFriends,
      history: history,
      lastExpiredCycle: lastExpiredCycle,
    ),
  );
}

Map<String, dynamic> leaderboardRow(
  int rank, {
  String? userId,
  String status = 'idle',
  int points = 1000,
}) =>
    <String, dynamic>{
      'rank': rank,
      'userId': userId ?? 'user-$rank',
      'username': 'member$rank',
      'displayName': 'Member $rank',
      'claimedTotalPoints': '$points',
      'lifetimeEarnedPoints': '$points',
      'sessionStatus': status,
    };
