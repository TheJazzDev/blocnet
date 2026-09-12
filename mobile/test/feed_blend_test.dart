import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/models/feed_blend.dart';
import 'package:flutter_test/flutter_test.dart';

Update _post(String id, {String project = 'p'}) => Update(
      id: id,
      title: id,
      content: id,
      description: id,
      adminId: 'a',
      projectId: project,
      priority: Priority.low,
      createdAt: DateTime(2026, 9, 12),
      secondaryTagIds: const [],
      secondaryTags: const [],
    );

List<Update> _posts(String prefix, int n) =>
    List.generate(n, (i) => _post('$prefix$i'));

void main() {
  group('followedShareFor', () {
    test('a member who follows nothing gets an entirely curated feed', () {
      expect(FeedBlend.followedShareFor(0), 0);
    });

    test('hits the three checkpoints the design specifies', () {
      // One gem: mostly curated.
      expect(FeedBlend.followedShareFor(1), lessThan(0.25));
      // Three gems: roughly half.
      expect(FeedBlend.followedShareFor(3), closeTo(0.5, 0.01));
      // Ten gems: saturated.
      expect(FeedBlend.followedShareFor(10), 1);
    });

    test('never exceeds one, however many gems are followed', () {
      expect(FeedBlend.followedShareFor(500), 1);
    });

    test('rises with every follow until saturation', () {
      var previous = -1.0;
      for (var n = 0; n <= FeedBlend.saturationFollows; n++) {
        final share = FeedBlend.followedShareFor(n);
        expect(share, greaterThan(previous));
        previous = share;
      }
    });
  });

  group('blend', () {
    test('day one is the curated feed, not an empty state', () {
      final out = FeedBlend.blend(
        followed: const [],
        curated: _posts('c', 40),
        followCount: 0,
      );
      // Enough to be worth scrolling, and capped so it is not unbounded.
      expect(out.length, greaterThan(10));
      expect(out.length, lessThan(40));
      expect(out.every((p) => p.id.startsWith('c')), isTrue);
    });

    test('never drops a followed post, at any follow count', () {
      for (final n in [1, 3, 6, 20]) {
        final followed = _posts('f', 5);
        final out = FeedBlend.blend(
          followed: followed,
          curated: _posts('c', 50),
          followCount: n,
        );
        for (final post in followed) {
          expect(out, contains(post), reason: 'followCount=$n dropped ${post.id}');
        }
      }
    });

    test('keeps followed posts in the order they were given', () {
      final followed = _posts('f', 6);
      final out = FeedBlend.blend(
        followed: followed,
        curated: _posts('c', 10),
        followCount: 3,
      );
      final seen = out.where((p) => p.id.startsWith('f')).toList();
      expect(seen, equals(followed));
    });

    test('one follow leans curated, six leans followed', () {
      double followedFraction(int followCount) {
        final out = FeedBlend.blend(
          followed: _posts('f', 4),
          curated: _posts('c', 60),
          followCount: followCount,
        );
        final own = out.where((p) => p.id.startsWith('f')).length;
        return own / out.length;
      }

      expect(followedFraction(1), lessThan(0.3));
      expect(followedFraction(6), greaterThan(0.5));
      expect(followedFraction(6), greaterThan(followedFraction(1)));
    });

    test('a saturated member still gets a few to discover', () {
      final out = FeedBlend.blend(
        followed: _posts('f', 8),
        curated: _posts('c', 30),
        followCount: 20,
      );
      final curatedCount = out.where((p) => p.id.startsWith('c')).length;
      // The feed must never dead-end, but must not drown them either.
      expect(curatedCount, greaterThan(0));
      expect(curatedCount, lessThan(5));
    });

    test('works when there is nothing curated to mix in', () {
      final followed = _posts('f', 3);
      final out = FeedBlend.blend(
        followed: followed,
        curated: const [],
        followCount: 3,
      );
      expect(out, equals(followed));
    });

    test('emits every post exactly once', () {
      final out = FeedBlend.blend(
        followed: _posts('f', 7),
        curated: _posts('c', 9),
        followCount: 3,
      );
      expect(out.map((p) => p.id).toSet().length, out.length);
    });

    test('spreads curated posts through the feed rather than appending them',
        () {
      final out = FeedBlend.blend(
        followed: _posts('f', 6),
        curated: _posts('c', 6),
        followCount: 3,
      );
      // With a roughly even mix, a curated post should appear in the first
      // handful instead of all of them landing after the followed ones.
      final firstCurated = out.indexWhere((p) => p.id.startsWith('c'));
      expect(firstCurated, lessThan(4));
    });
  });

  group('defaultsToFollowing', () {
    test('a thin board opens on For you, a filled one on Following', () {
      expect(FeedBlend.defaultsToFollowing(0), isFalse);
      expect(FeedBlend.defaultsToFollowing(2), isFalse);
      expect(FeedBlend.defaultsToFollowing(3), isTrue);
      expect(FeedBlend.defaultsToFollowing(10), isTrue);
    });
  });
}
