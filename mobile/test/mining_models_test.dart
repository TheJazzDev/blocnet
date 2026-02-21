import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses mining snapshot payload', () {
    final snapshot = MiningSnapshot.fromApi({
      'asOf': '2026-02-21T12:00:00.000Z',
      'config': {
        'enabled': true,
        'referralsEnabled': true,
        'cycleHours': 24,
        'basePointsPerCycle': 120,
        'perActiveReferralBoostBps': 500,
        'maxBoostBps': 10000,
        'activeReferralWindowHours': 168,
        'referralBindWindowHours': 24,
      },
      'balance': {
        'claimedTotalPoints': 360,
        'maturedUnclaimedPoints': 120,
        'lifetimeEarnedPoints': 480,
      },
      'session': {
        'id': 'session-1',
        'status': 'running',
        'startsAt': '2026-02-21T00:00:00.000Z',
        'endsAt': '2026-02-22T00:00:00.000Z',
        'progressPct': 0.5,
        'pointsMinedSoFar': 60,
        'effectivePointsPerCycle': 120,
        'boostBpsSnapshot': 0,
        'activeReferralsSnapshot': 0,
      },
      'referral': {
        'code': 'AB12CD34',
        'referredBy': null,
        'canBindUntil': '2026-02-22T00:00:00.000Z',
        'bindWindowOpen': true,
        'activeDirectReferrals': 1,
        'totalDirectReferrals': 3,
      },
    });

    expect(snapshot.config.cycleHours, 24);
    expect(snapshot.balance.claimedTotalPoints, 360);
    expect(snapshot.session.isRunning, isTrue);
    expect(snapshot.referral.code, 'AB12CD34');
  });

  test('parses downline response payload', () {
    final response = DownlineResponse.fromApi({
      'data': [
        {
          'id': 'user-2',
          'email': 'user2@example.com',
          'displayName': 'User Two',
          'status': 'claimable',
          'isActive': true,
          'progressPct': 1,
          'claimedTotalPoints': 240,
          'referredAt': '2026-02-21T00:00:00.000Z',
          'lastActiveAt': '2026-02-21T08:00:00.000Z',
        },
      ],
      'total': 1,
      'limit': 20,
      'offset': 0,
    });

    expect(response.total, 1);
    expect(response.data.first.status, 'claimable');
    expect(response.data.first.claimedTotalPoints, 240);
  });
}
