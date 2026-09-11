import 'package:blocnet/features/mining/data/models/mining_claim_models.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/data/repositories/mining_api_repository.dart';
import 'package:blocnet/features/mining/presentation/widgets/mining_hourly_history_card.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake client standing in for `POST /mining/claim`, which answers 200 both
/// when it pays out and when it forfeits an expired cycle.
class _FakeMiningRepository extends MiningApiRepository {
  _FakeMiningRepository({
    required this.claimBody,
    this.snapshotBody,
  });

  final Map<String, dynamic> claimBody;
  Map<String, dynamic>? snapshotBody;
  int claimCalls = 0;

  @override
  Future<MiningClaimResult> claimMining() async {
    claimCalls++;
    return MiningClaimResult.fromApi(claimBody);
  }

  @override
  Future<MiningSnapshot?> fetchMiningSnapshot() async {
    final body = snapshotBody;
    return body == null ? null : MiningSnapshot.fromApi(body);
  }

  @override
  Future<ReferralSummaryModel?> fetchReferralSummary() async => null;

  @override
  Future<DownlineResponse?> fetchDownline({int limit = 20, int offset = 0}) async =>
      null;

  @override
  Future<MiningLeaderboardResponse?> fetchLeaderboard({
    int limit = 20,
    int offset = 0,
  }) async =>
      null;
}

Map<String, dynamic> _snapshotBody({
  required int claimedTotalPoints,
  required int maturedUnclaimedPoints,
}) {
  return <String, dynamic>{
    'asOf': '2026-09-12T12:00:00.000Z',
    'config': {
      'enabled': true,
      'referralsEnabled': true,
      'cycleHours': 24,
      'basePointsPerCycle': 120,
      'perActiveReferralBoostBps': 500,
      'maxBoostBps': 10000,
      'activeReferralWindowHours': 168,
      'referralBindWindowHours': 24,
      'claimWindowHours': 48,
    },
    'balance': {
      'claimedTotalPoints': '$claimedTotalPoints',
      'maturedUnclaimedPoints': maturedUnclaimedPoints,
      'lifetimeEarnedPoints':
          '${claimedTotalPoints + maturedUnclaimedPoints}',
    },
    'session': {'id': null, 'status': 'idle'},
    'referral': {'code': 'AB12CD34'},
    'hourlyHistory': const <dynamic>[],
  };
}

/// Real shape of the forfeited-claim response (200, `ok:false`).
final _expiredClaimBody = <String, dynamic>{
  'ok': false,
  'status': 'expired',
  'code': 'claim_window_expired',
  'message': 'That mining cycle expired.',
  'claimedPoints': 0,
  'forfeitedPoints': 120,
  'expiredCycles': [
    {
      'sessionId': 'session-expired',
      'startsAt': '2026-09-08T00:00:00.000Z',
      'endsAt': '2026-09-09T00:00:00.000Z',
      'claimDeadline': '2026-09-11T00:00:00.000Z',
      'expiredAt': '2026-09-12T12:00:00.000Z',
      'forfeitedPoints': 120,
    },
  ],
  'balance': {
    'claimedTotalPoints': '360',
    'maturedUnclaimedPoints': 0,
    'lifetimeEarnedPoints': '360',
  },
  'nextSession': {
    'id': 'session-next',
    'status': 'running',
    'startsAt': '2026-09-12T12:00:00.000Z',
    'endsAt': '2026-09-13T12:00:00.000Z',
    'progressPct': 0,
    'pointsMinedSoFar': 0,
    'effectivePointsPerCycle': 120,
  },
};

final _claimedBody = <String, dynamic>{
  'ok': true,
  'status': 'claimed',
  'sessionId': 'session-1',
  'claimedAt': '2026-09-12T12:00:00.000Z',
  'claimedPoints': 120,
  'expiredCycles': const <dynamic>[],
  'balance': {
    'claimedTotalPoints': '480',
    'maturedUnclaimedPoints': 0,
    'lifetimeEarnedPoints': '480',
  },
  'nextSession': {
    'id': 'session-next',
    'status': 'running',
    'startsAt': '2026-09-12T12:00:00.000Z',
    'endsAt': '2026-09-13T12:00:00.000Z',
    'progressPct': 0,
    'pointsMinedSoFar': 0,
    'effectivePointsPerCycle': 120,
  },
};

void main() {
  group('MiningClaimResult', () {
    test('an expired 200 response does not read as success', () {
      final result = MiningClaimResult.fromApi(_expiredClaimBody);

      expect(result.isClaimed, isFalse);
      expect(result.isExpired, isTrue);
      expect(result.claimedPoints, 0);
      expect(result.forfeitedPoints, 120);
      expect(result.code, 'claim_window_expired');
      expect(result.expiredCycles, hasLength(1));
      expect(result.expiredCycles.single.sessionId, 'session-expired');
      expect(result.startedNextCycle, isTrue);
    });

    test('a successful claim still reads as success', () {
      final result = MiningClaimResult.fromApi(_claimedBody);

      expect(result.isClaimed, isTrue);
      expect(result.isExpired, isFalse);
      expect(result.claimedPoints, 120);
      expect(result.expiredCycles, isEmpty);
    });

    test('an unreadable body is never reported as a payout', () {
      final result = MiningClaimResult.unknown();

      expect(result.isClaimed, isFalse);
      expect(result.claimedPoints, 0);
    });

    test('start carries forfeited cycles', () {
      final result = MiningStartResult.fromApi(<String, dynamic>{
        'ok': true,
        'status': 'started',
        'expiredCycles': [
          {'sessionId': 'a', 'forfeitedPoints': 60},
          {'sessionId': 'b', 'forfeitedPoints': 60},
        ],
      });

      expect(result.hasExpiredCycles, isTrue);
      expect(result.forfeitedPoints, 120);
    });
  });

  group('MiningStore.claimMining', () {
    test('an expired claim is an outcome, not an error or a silent win',
        () async {
      final repo = _FakeMiningRepository(
        claimBody: _expiredClaimBody,
        snapshotBody: _snapshotBody(
          claimedTotalPoints: 360,
          maturedUnclaimedPoints: 0,
        ),
      );
      final store = MiningStore(repository: repo);

      final result = await store.claimMining();

      expect(repo.claimCalls, 1);
      expect(result?.isClaimed, isFalse);
      expect(store.lastClaimResult?.isExpired, isTrue);
      // Not styled as a crash...
      expect(store.lastError, isNull);
      // ...but the user is told, plainly, with the amount and what happens next.
      expect(store.forfeitNotice, isNotNull);
      expect(store.forfeitNotice, contains('120 BNP'));
      expect(store.forfeitNotice, contains('forfeited'));
      expect(store.forfeitNotice, contains('new cycle has already started'));
    });

    test('a successful claim reports the paid amount and no forfeit notice',
        () async {
      final repo = _FakeMiningRepository(
        claimBody: _claimedBody,
        snapshotBody: _snapshotBody(
          claimedTotalPoints: 480,
          maturedUnclaimedPoints: 0,
        ),
      );
      final store = MiningStore(repository: repo);

      final result = await store.claimMining();

      expect(result?.isClaimed, isTrue);
      expect(result?.claimedPoints, 120);
      expect(store.forfeitNotice, isNull);
      expect(store.lastError, isNull);
      expect(store.snapshot?.balance.claimedTotalPoints, 480);
    });

    test('a balance that drops after a forfeit is not masked by the cache',
        () async {
      // The cache says 500 matured points are waiting.
      final repo = _FakeMiningRepository(
        claimBody: _expiredClaimBody,
        snapshotBody: _snapshotBody(
          claimedTotalPoints: 360,
          maturedUnclaimedPoints: 500,
        ),
      );
      final store = MiningStore(repository: repo);
      await store.loadSnapshot();
      expect(store.snapshot?.balance.maturedUnclaimedPoints, 500);
      expect(store.snapshot?.balance.lifetimeEarnedPoints, 860);

      // Those checkpoints get forfeited, so the server stops counting them.
      repo.snapshotBody = _snapshotBody(
        claimedTotalPoints: 360,
        maturedUnclaimedPoints: 0,
      );
      await store.claimMining();

      expect(store.snapshot?.balance.maturedUnclaimedPoints, 0);
      expect(store.snapshot?.balance.lifetimeEarnedPoints, 360);
    });
  });

  group('MiningHourlyHistoryCard', () {
    MiningHourlyCheckpointModel checkpoint({
      required String id,
      required String status,
      String? claimedAt,
      String? expiredAt,
    }) {
      return MiningHourlyCheckpointModel.fromApi(<String, dynamic>{
        'id': id,
        'sessionId': 'session-1',
        'hourIndex': 1,
        'hourStartAt': '2026-09-12T10:00:00.000Z',
        'hourEndAt': '2026-09-12T11:00:00.000Z',
        'points': 5,
        'activeReferralsSnapshot': 0,
        'boostBpsSnapshot': 0,
        'claimedAt': claimedAt,
        'expiredAt': expiredAt,
        'status': status,
      });
    }

    testWidgets('renders claimed, unclaimed and the third expired state',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MiningHourlyHistoryCard(
                entries: [
                  checkpoint(
                    id: 'a',
                    status: 'claimed',
                    claimedAt: '2026-09-12T12:00:00.000Z',
                  ),
                  checkpoint(
                    id: 'b',
                    status: 'expired',
                    expiredAt: '2026-09-12T12:00:00.000Z',
                  ),
                  checkpoint(id: 'c', status: 'unclaimed'),
                ],
                isLoading: false,
                basePointsPerCycle: 120,
                cycleHours: 24,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Claimed'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Unclaimed'), findsOneWidget);

      // Forfeited accrual is never dressed up as an earning.
      expect(find.text('forfeited 5'), findsOneWidget);
      expect(find.text('settled 5'), findsNWidgets(2));
    });

    test('checkpoint models expose the third state', () {
      final expired = checkpoint(
        id: 'b',
        status: 'expired',
        expiredAt: '2026-09-12T12:00:00.000Z',
      );

      expect(expired.isExpired, isTrue);
      expect(expired.isClaimed, isFalse);
      expect(expired.isUnclaimed, isFalse);
      expect(expired.expiredAt, isNotNull);
    });
  });
}
