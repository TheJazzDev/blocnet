import 'package:blocnet/features/gems/domain/gem_keeper.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/gems/domain/gems_ordering.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gems_fixtures.dart';

void main() {
  group('GemKeeper', () {
    test('names the admin when the admin keeps the gem', () {
      final p = gemProject('g1',
          owner: admin('admin-1', username: 'ana'),
          reliability: const OwnerReliability(
            profileId: 'admin-1',
            standing: ReliabilityStanding.slipping,
            coverage: 0.6,
          ));
      final keeper = GemKeeper.forProject(p)!;
      expect(keeper.label, '@ana');
      expect(keeper.standing, ReliabilityStanding.slipping);
      expect(keeper.coverageLine, '60% of gems current');
    });

    test('names an assigned hunter from the leaderboard', () {
      final p = gemProject('g1',
          reliability: const OwnerReliability(
            profileId: 'hunter-9',
            standing: ReliabilityStanding.reliable,
            coverage: 0.8,
          ));
      final keeper = GemKeeper.forProject(p, known: {
        'hunter-9': hunter('hunter-9', name: 'Bo', username: 'bo', gems: 5),
      })!;
      expect(keeper.label, '@bo');
      expect(keeper.coverageLine, '4 of 5 gems current');
    });

    test('never shows the admin for someone else', () {
      final p = gemProject('g1',
          reliability: const OwnerReliability(
            profileId: 'hunter-9',
            standing: ReliabilityStanding.quiet,
          ));
      final keeper = GemKeeper.forProject(p)!;
      expect(keeper.profileId, 'hunter-9');
      expect(keeper.name, 'Hunter');
      expect(keeper.coverageLine, isNull);
    });
  });

  group('GemListings', () {
    test('uses the server last update when the list lacks it', () {
      final p = gemProject('g1', updatesCount: 7, lastUpdateAt: daysAgo(20));
      final gem = listing(p);
      expect(gem.newest, isNull);
      expect(gem.lastUpdateAt, daysAgo(20));
      expect(gem.newestIsLatest, isFalse);
      expect(gem.updatesCount, 7);
      expect(gem.isQuiet, isTrue);
    });

    test('a gem updated this week is not quiet', () {
      final p = gemProject('g1', lastUpdateAt: daysAgo(2));
      final gem = listing(p, updates: [gemUpdate('u1', 'g1', at: daysAgo(2))]);
      expect(gem.newestIsLatest, isTrue);
      expect(gem.isQuiet, isFalse);
    });

    test('picks the next deadline that is still ahead', () {
      final p = gemProject('g1');
      final gem = listing(p, updates: [
        gemUpdate('past', 'g1', at: daysAgo(5), deadline: daysAgo(1)),
        gemUpdate('late', 'g1', at: daysAgo(4), deadline: daysAgo(-6)),
        gemUpdate('soon', 'g1', at: daysAgo(3), deadline: daysAgo(-1)),
      ]);
      expect(gem.nextDeadline!.id, 'soon');
    });
  });

  group('GemsOrdering', () {
    List<GemListing> build(List<Project> projects, List<Update> updates) =>
        GemListings.build(projects: projects, updates: updates, now: gemsNow);

    test('discover filters by chain and sorts by real numbers', () {
      final gems = build([
        gemProject('a', tag: 'Core', followers: 5, lastUpdateAt: daysAgo(1)),
        gemProject('b', tag: 'Solana', followers: 50, lastUpdateAt: daysAgo(9)),
        gemProject('c', tag: 'Core', followers: 1, createdAt: daysAgo(1)),
      ], const []);

      expect(
        GemsOrdering.discover(gems, sort: GemSort.mostActive).map((g) => g.id),
        ['a', 'b', 'c'],
      );
      expect(
        GemsOrdering.discover(gems, sort: GemSort.mostFollowed)
            .map((g) => g.id),
        ['b', 'a', 'c'],
      );
      expect(
        GemsOrdering.discover(gems, sort: GemSort.newest, tag: 'core')
            .map((g) => g.id),
        ['c', 'a'],
      );
      expect(GemsOrdering.tags(gems), ['Core', 'Solana']);
    });

    test('moving keeps gems updated this week, newest first', () {
      final gems = build(
        [gemProject('a'), gemProject('b'), gemProject('c')],
        [
          gemUpdate('ua', 'a', at: daysAgo(3)),
          gemUpdate('ub', 'b', at: daysAgo(1)),
          gemUpdate('uc', 'c', at: daysAgo(10)),
        ],
      );
      expect(GemsOrdering.moving(gems, gemsNow).map((g) => g.id), ['b', 'a']);
    });

    test('board puts deadlines first, then fresh updates, then the rest', () {
      final gems = build(
        [gemProject('calm'), gemProject('fresh'), gemProject('due')],
        [
          gemUpdate('u1', 'calm', at: daysAgo(12)),
          gemUpdate('u2', 'fresh', at: daysAgo(1)),
          gemUpdate('u3', 'due', at: daysAgo(9), deadline: daysAgo(-1)),
        ],
      );
      expect(
        GemsOrdering.board(gems, gemsNow).map((g) => g.id),
        ['due', 'fresh', 'calm'],
      );
    });
  });
}
