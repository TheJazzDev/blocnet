import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge_artwork.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

UserLevelModel _level({
  required String slug,
  int level = 8,
  String iconUrl = '',
  String? color = '#8B5CF6',
}) {
  return UserLevelModel(
    id: 'lvl-$slug',
    slug: slug,
    name: slug,
    description: '',
    iconUrl: iconUrl,
    level: level,
    requiredBnp: '0',
    requiredComments: 0,
    requiredDaysActive: 0,
    requiredQuests: 0,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: color,
    isActive: true,
    sortOrder: level,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  group('LevelBadgeAssets', () {
    test('maps every level number 1-15 to a bundled svg', () {
      for (var n = 1; n <= 15; n++) {
        expect(
          LevelBadgeAssets.pathFor(level: n),
          'assets/badges/${LevelBadgeAssets.byLevel[n]}.svg',
        );
      }
    });

    test('level number wins even when the slug drifted', () {
      expect(
        LevelBadgeAssets.pathFor(level: 3, slug: 'blocnet-member'),
        'assets/badges/pathfinder.svg',
      );
    });

    test('falls back to slug, ignoring the blocnet- prefix and case', () {
      expect(
        LevelBadgeAssets.pathFor(level: 0, slug: ' Blocnet-Champion '),
        'assets/badges/champion.svg',
      );
    });

    test('returns null when neither number nor slug is known', () {
      expect(LevelBadgeAssets.pathFor(level: 99, slug: 'grandmaster'), isNull);
      expect(LevelBadgeAssets.pathFor(level: 0), isNull);
    });
  });

  group('LevelBadgeArtwork', () {
    testWidgets('renders the bundled svg when the slug is known',
        (tester) async {
      await tester.pumpWidget(
        _wrap(LevelBadgeArtwork(level: _level(slug: 'champion'), size: 20)),
      );
      await tester.pump();

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(LevelNumberFallback), findsNothing);
    });

    testWidgets('falls back to the level number when nothing is available',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          LevelBadgeArtwork(level: _level(slug: 'unknown', level: 42), size: 20),
        ),
      );

      expect(find.byType(SvgPicture), findsNothing);
      expect(find.byType(LevelNumberFallback), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('prefers the bundled svg over a remote iconUrl', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LevelBadgeArtwork(
            level: _level(slug: 'legend', iconUrl: 'https://example.com/x.png'),
            size: 20,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SvgPicture), findsOneWidget);
    });
  });

  group('LevelBadge', () {
    testWidgets('shows level number and name when asked', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LevelBadge(
            level: _level(slug: 'elite', level: 9),
            showLevelNumber: true,
            showName: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Level 9 • elite'), findsOneWidget);
    });

    testWidgets('LevelBadgeIcon shows artwork only, with a tooltip',
        (tester) async {
      await tester.pumpWidget(
        _wrap(LevelBadgeIcon(level: _level(slug: 'titan', level: 14))),
      );
      await tester.pump();

      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.textContaining('Level'), findsNothing);
    });
  });

  test('parseLevelColor handles 6 and 8 digit hex and bad input', () {
    expect(parseLevelColor('#8B5CF6'), const Color(0xFF8B5CF6));
    expect(parseLevelColor('808B5CF6'), const Color(0x808B5CF6));
    expect(parseLevelColor('nope'), Colors.grey.shade600);
    expect(parseLevelColor(null), Colors.grey.shade600);
  });
}
