import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/models/quiet_gem.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 9, 12);

Project _project(String id, {DateTime? createdAt, String? hunter}) => Project(
      id: id,
      logo: '',
      name: 'Gem $id',
      details: 'd',
      adminId: 'a',
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      primaryTagId: 't',
      primaryTag: const PrimaryTag(id: 't', name: 'Core'),
      description: 'd',
      followersCount: 1,
      admin: hunter == null
          ? null
          : Admin(
              id: 'a',
              name: 'Hunter',
              username: hunter,
              imageUrl: '',
              followers: 1,
            ),
    );

Update _update(String project, DateTime at, {String title = 'Farming live'}) =>
    Update(
      id: '$project-$at',
      title: title,
      content: 'body',
      description: 'body',
      adminId: 'a',
      projectId: project,
      priority: Priority.low,
      createdAt: at,
      secondaryTagIds: const [],
      secondaryTags: const [],
    );

List<QuietGem> detect({
  required List<Project> projects,
  required Set<String> followed,
  required List<Update> posts,
}) =>
    QuietGems.detect(
      projects: projects,
      followedProjectIds: followed,
      posts: posts,
      now: _now,
    );

void main() {
  group('QuietGems.detect', () {
    test('a gem touched today is not quiet', () {
      final quiet = detect(
        projects: [_project('a')],
        followed: {'a'},
        posts: [_update('a', _now)],
      );
      expect(quiet, isEmpty);
    });

    test('a gem untouched for three weeks is quiet', () {
      final quiet = detect(
        projects: [_project('a')],
        followed: {'a'},
        posts: [_update('a', _now.subtract(const Duration(days: 21)))],
      );
      expect(quiet, hasLength(1));
      expect(quiet.first.daysSilent, 21);
    });

    test('the threshold is a boundary, not a range', () {
      // A hunter on a two-week holiday is not an abandoned gem.
      final justInside = detect(
        projects: [_project('a')],
        followed: {'a'},
        posts: [_update('a', _now.subtract(const Duration(days: 13)))],
      );
      expect(justInside, isEmpty);

      final justOutside = detect(
        projects: [_project('a')],
        followed: {'a'},
        posts: [_update('a', _now.subtract(const Duration(days: 15)))],
      );
      expect(justOutside, hasLength(1));
    });

    test('only followed gems are reported', () {
      final quiet = detect(
        projects: [_project('a'), _project('b')],
        followed: {'a'},
        posts: [
          _update('a', _now.subtract(const Duration(days: 30))),
          _update('b', _now.subtract(const Duration(days: 90))),
        ],
      );
      expect(quiet.map((g) => g.project.id), ['a']);
    });

    test('the newest update decides, not the oldest', () {
      final quiet = detect(
        projects: [_project('a')],
        followed: {'a'},
        posts: [
          _update('a', _now.subtract(const Duration(days: 400))),
          _update('a', _now.subtract(const Duration(days: 2))),
        ],
      );
      expect(quiet, isEmpty);
    });

    test('a gem whose hunter never posted counts from when it was listed', () {
      final quiet = detect(
        projects: [
          _project('a', createdAt: _now.subtract(const Duration(days: 60)))
        ],
        followed: {'a'},
        posts: const [],
      );
      expect(quiet, hasLength(1));
      expect(quiet.first.lastUpdate, isNull);
      expect(quiet.first.daysSilent, 60);
    });

    test('a gem listed yesterday with no updates is not yet quiet', () {
      final quiet = detect(
        projects: [
          _project('a', createdAt: _now.subtract(const Duration(days: 1)))
        ],
        followed: {'a'},
        posts: const [],
      );
      expect(quiet, isEmpty);
    });

    test('worst offender comes first', () {
      final quiet = detect(
        projects: [_project('a'), _project('b'), _project('c')],
        followed: {'a', 'b', 'c'},
        posts: [
          _update('a', _now.subtract(const Duration(days: 20))),
          _update('b', _now.subtract(const Duration(days: 90))),
          _update('c', _now.subtract(const Duration(days: 40))),
        ],
      );
      expect(quiet.map((g) => g.project.id), ['b', 'c', 'a']);
    });

    test('carries the last words so the card can quote them', () {
      final quiet = detect(
        projects: [_project('a')],
        followed: {'a'},
        posts: [
          _update(
            'a',
            _now.subtract(const Duration(days: 23)),
            title: 'Farming round 2 is live',
          )
        ],
      );
      expect(quiet.first.lastUpdate?.title, 'Farming round 2 is live');
    });
  });

  group('QuietGem.hunterHandle', () {
    test('prefixes an @ once, and only once', () {
      final withPlain = detect(
        projects: [_project('a', hunter: 'ada')],
        followed: {'a'},
        posts: [_update('a', _now.subtract(const Duration(days: 30)))],
      ).first;
      expect(withPlain.hunterHandle, '@ada');

      final withAt = detect(
        projects: [_project('a', hunter: '@ada')],
        followed: {'a'},
        posts: [_update('a', _now.subtract(const Duration(days: 30)))],
      ).first;
      expect(withAt.hunterHandle, '@ada');
    });

    test('is null when the gem carries no hunter, so the card can adapt', () {
      final gem = detect(
        projects: [_project('a')],
        followed: {'a'},
        posts: [_update('a', _now.subtract(const Duration(days: 30)))],
      ).first;
      expect(gem.hunterHandle, isNull);
    });
  });
}
