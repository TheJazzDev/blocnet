import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_leaderboard_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shaped exactly as `GET /hunters/:id/reliability` answers.
Map<String, dynamic> reliabilityJson({
  String standing = 'slipping',
  Object? coverage = 0.667,
}) =>
    {
      'profileId': '6d4ec119-bbb0-4d5a-b72e-569c5fb73916',
      'username': 'nexa',
      'displayName': 'Hunter Nexa',
      'avatarUrl': null,
      'level': {
        'id': 'lvl-3',
        'slug': 'builder',
        'name': 'Builder',
        'level': 3,
        'iconUrl': 'https://cdn.example/l3.svg',
        'color': null,
      },
      'standing': standing,
      'coverage': coverage,
      'cadenceDays': 4.5,
      'response': null,
      'gemsOwned': 3,
      'updates30d': 6,
      'followersTotal': 8,
      'tipsReceivedTotal': '123456789012345678901234567890',
      'tipsCurrencyCode': 'BNP',
      'tipsCurrencyDecimals': 3,
      'membersWaiting': 2,
      'openReports': 1,
      'computedAt': '2026-09-16T10:09:01.057Z',
    };

void main() {
  group('HunterReliability.fromApi', () {
    test('reads every field, keeping big tip totals exact', () {
      final r = HunterReliability.fromApi(reliabilityJson());

      expect(r.profileId, '6d4ec119-bbb0-4d5a-b72e-569c5fb73916');
      expect(r.name, 'Hunter Nexa');
      expect(r.level?.name, 'Builder');
      expect(r.level?.level, 3);
      expect(r.level?.color, isNull);
      expect(r.standing, ReliabilityStanding.slipping);
      expect(r.coverage, 0.667);
      expect(r.cadenceDays, 4.5);
      expect(r.response, isNull);
      expect(r.gemsOwned, 3);
      expect(r.updates30d, 6);
      expect(r.followersTotal, 8);
      expect(
        r.tipsReceivedTotal,
        BigInt.parse('123456789012345678901234567890'),
      );
      expect(r.tipsCurrencyCode, 'BNP');
      expect(r.tipsCurrencyDecimals, 3);
      expect(r.membersWaiting, 2);
      expect(r.openReports, 1);
      expect(r.computedAt, DateTime.utc(2026, 9, 16, 10, 9, 1, 57));
    });

    test('maps every standing, including new, and tolerates unknown ones', () {
      ReliabilityStanding parse(String s) =>
          HunterReliability.fromApi(reliabilityJson(standing: s)).standing;
      expect(parse('reliable'), ReliabilityStanding.reliable);
      expect(parse('quiet'), ReliabilityStanding.quiet);
      expect(parse('new'), ReliabilityStanding.newHunter);
      expect(parse('legendary'), ReliabilityStanding.unknown);
      expect(ReliabilityStanding.newHunter.label, 'New');
    });

    test('keeps a null or integer coverage as the backend sent it', () {
      expect(
        HunterReliability.fromApi(reliabilityJson(coverage: null)).coverage,
        isNull,
      );
      expect(
        HunterReliability.fromApi(reliabilityJson(coverage: 1)).coverage,
        1.0,
      );
    });

    test('degrades to empty values on a sparse payload', () {
      final r = HunterReliability.fromApi(const {'profileId': 'x'});
      expect(r.standing, ReliabilityStanding.unknown);
      expect(r.level, isNull);
      expect(r.gemsOwned, 0);
      expect(r.tipsReceivedTotal, BigInt.zero);
      expect(r.name, 'Hunter');
    });
  });

  group('HunterBoard.fromApi', () {
    final json = {
      'reliability': reliabilityJson(),
      'gems': [
        {
          'projectId': 'p-quiet',
          'name': 'Never Posted',
          'logoUrl': null,
          'primaryTag': 'DeFi',
          'followersCount': 0,
          'listedAt': '2026-08-01T00:00:00.000Z',
          'lastActivityAt': '2026-08-01T00:00:00.000Z',
          'lastUpdate': null,
          'daysQuiet': 46,
          'state': 'quiet',
          'membersWaiting': 4,
          'openReports': 1,
          'nextDeadlineAt': null,
        },
        {
          'projectId': 'p-current',
          'name': 'BSC Launch Flow',
          'logoUrl': null,
          'primaryTag': 'Binance Smart Chain',
          'followersCount': 3,
          'listedAt': '2026-09-12T17:45:01.587Z',
          'lastActivityAt': '2026-09-12T17:45:01.990Z',
          'lastUpdate': {
            'id': 'u-1',
            'title': 'BSC Token Claim Process',
            'publishedAt': '2026-09-12T17:45:01.990Z',
          },
          'daysQuiet': 3,
          'state': 'current',
          'membersWaiting': 0,
          'openReports': 0,
          'nextDeadlineAt': '2026-09-16T19:25:22.886Z',
        },
      ],
    };

    test('reads reliability and gems, keeping the server order', () {
      final board = HunterBoard.fromApi(json);

      expect(board.reliability.gemsOwned, 3);
      expect(board.gems.map((g) => g.projectId), ['p-quiet', 'p-current']);

      final quiet = board.gems.first;
      expect(quiet.state, GemState.quiet);
      expect(quiet.lastUpdate, isNull);
      expect(quiet.logoUrl, isNull);
      expect(quiet.daysQuiet, 46);
      expect(quiet.membersWaiting, 4);
      expect(quiet.openReports, 1);
      expect(quiet.nextDeadlineAt, isNull);

      final current = board.gems.last;
      expect(current.state, GemState.current);
      expect(current.primaryTag, 'Binance Smart Chain');
      expect(current.followersCount, 3);
      expect(current.lastUpdate?.id, 'u-1');
      expect(current.lastUpdate?.title, 'BSC Token Claim Process');
      expect(
        current.lastUpdate?.publishedAt,
        DateTime.utc(2026, 9, 12, 17, 45, 1, 990),
      );
      expect(current.listedAt, DateTime.utc(2026, 9, 12, 17, 45, 1, 587));
      expect(
          current.nextDeadlineAt, DateTime.utc(2026, 9, 16, 19, 25, 22, 886));
    });

    test('maps due and unknown gem states', () {
      expect(GemState.fromApi('due'), GemState.due);
      expect(GemState.fromApi('archived'), GemState.unknown);
    });

    test('an empty board has no gems', () {
      final board = HunterBoard.fromApi({
        'reliability': reliabilityJson(standing: 'new', coverage: null),
        'gems': <Object>[],
      });
      expect(board.gems, isEmpty);
      expect(board.reliability.standing, ReliabilityStanding.newHunter);
    });
  });

  group('HunterLeaderboardPage.fromApi', () {
    test('reads ranked entries and the cursor', () {
      final page = HunterLeaderboardPage.fromApi({
        'items': [
          {...reliabilityJson(standing: 'reliable'), 'rank': 1},
          {...reliabilityJson(), 'profileId': 'second', 'rank': 2},
        ],
        'nextCursor': '2',
      });
      expect(page.entries.map((e) => e.rank), [1, 2]);
      expect(page.entries.first.reliability.standing,
          ReliabilityStanding.reliable);
      expect(page.entries.last.reliability.profileId, 'second');
      expect(page.nextCursor, '2');
      expect(page.hasMore, isTrue);
    });

    test('the last page has no cursor', () {
      final page = HunterLeaderboardPage.fromApi({
        'items': <Object>[],
        'nextCursor': null,
      });
      expect(page.entries, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });

  group('OwnerReliability.fromApi', () {
    test('reads the compact card form, or null when absent', () {
      final owner = OwnerReliability.fromApi({
        'profileId': 'h1',
        'standing': 'reliable',
        'coverage': 0.9,
      });
      expect(owner?.profileId, 'h1');
      expect(owner?.standing, ReliabilityStanding.reliable);
      expect(owner?.coverage, 0.9);
      expect(OwnerReliability.fromApi(null), isNull);
    });
  });
}
