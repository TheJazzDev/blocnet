import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/gallery/badge_tile.dart';
import 'package:blocnet/features/badges/presentation/widgets/progress_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BadgeModel _badge({String name = 'Early Believer', int points = 250}) {
  return BadgeModel(
    id: 'b1',
    slug: 'b1',
    name: name,
    description: 'Joined in the first month.',
    imageUrl: '',
    category: BadgeCategory.social,
    rarity: BadgeRarity.legendary,
    pointsRequirement: points,
    isActive: true,
    sortOrder: 1,
    createdAt: DateTime(2026),
  );
}

Future<void> _pumpGrid(WidgetTester tester, List<Widget> tiles) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GridView.count(
          padding: const EdgeInsets.all(14),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: (375 - 28 - 10) / 2 / kBadgeTileExtent,
          children: tiles,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('badge tiles fit at 375px with long names and big numbers',
      (tester) async {
    final longName = _badge(
      name: 'The Extremely Long Community Pillar Of The Season Award',
      points: 123456789,
    );
    await _pumpGrid(tester, [
      BadgeTile(badge: longName, isEarned: false, isPrimary: false),
      BadgeTile(
        badge: longName,
        isEarned: true,
        isPrimary: true,
        earnedAt: DateTime(2026, 9, 1),
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Unlocks at 123456789 pts'), findsOneWidget);
    expect(find.text('Earned 09/01/2026'), findsOneWidget);
    expect(find.text('PRIMARY'), findsOneWidget);
    expect(find.text('LEGENDARY'), findsNWidgets(2));
  });

  testWidgets('badge tile is flat: no gradient or shadow', (tester) async {
    await _pumpGrid(tester, [
      BadgeTile(badge: _badge(), isEarned: true, isPrimary: false),
    ]);

    final decorated = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>();
    expect(decorated.any((d) => d.gradient != null), isFalse);
    expect(decorated.any((d) => d.boxShadow != null), isFalse);
  });

  test('raw exception text never reaches the screen', () {
    expect(
      progressErrorText('SocketException: Failed host lookup',
          fallback: 'fallback'),
      'fallback',
    );
    expect(progressErrorText(null, fallback: 'fallback'), 'fallback');
    expect(
      progressErrorText('Quest not found', fallback: 'fallback'),
      'Quest not found',
    );
  });

  test('category and rarity tones come from the core palette', () {
    expect(BadgeRarity.epic.tone, AppColors.tagPartnership);
    expect(BadgeCategory.social.tone, AppColors.tagInfo);
  });
}
