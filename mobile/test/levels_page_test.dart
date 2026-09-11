import 'package:blocnet/features/levels/presentation/pages/levels_page.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_card_item.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_detail_sheet.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_list_item.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_progress_card.dart';
import 'package:blocnet/features/levels/presentation/widgets/tier_section_header.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/engagement/levels_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tierColors = {
  1: '#8A96A8', 2: '#8A96A8', 3: '#8A96A8',
  4: '#2AA876', 5: '#2AA876', 6: '#2AA876',
  7: '#8B5CF6', 8: '#8B5CF6', 9: '#8B5CF6',
  10: '#F0B429', 11: '#F0B429', 12: '#F0B429',
  13: '#E23D4A', 14: '#E23D4A', 15: '#E23D4A',
};

Map<String, dynamic> _levelJson(int level) => {
      'id': 'lvl-$level',
      'slug': 'level-$level',
      'name': 'Rank $level',
      'description': 'Description for level $level',
      'iconUrl': '',
      'level': level,
      'requiredBnp': '${level * 1000}',
      'requiredComments': level * 2,
      'requiredDaysActive': level,
      'requiredQuests': level > 5 ? 1 : 0,
      'requiredUpdates': level > 8 ? 1 : 0,
      'requiredProjects': level > 11 ? 1 : 0,
      'color': _tierColors[level],
      'isActive': true,
      'sortOrder': level,
    };

class _FakeApiClient extends ApiClient {
  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    if (path == '/levels') {
      return [for (var n = 1; n <= 15; n++) _levelJson(n)];
    }
    if (path == '/levels/me') {
      return {
        'currentLevel': _levelJson(5),
        'nextLevel': _levelJson(6),
        'achievedAt': '2026-01-01T00:00:00Z',
        'metrics': {
          'totalBnpEarned': '5200',
          'totalComments': 10,
          'totalDaysActive': 5,
          'totalQuestsCompleted': 0,
          'totalUpdates': 0,
          'totalProjects': 0,
        },
        'progressToNext': {
          'bnp': {'current': '5200', 'required': '6000', 'percentage': 86},
          'comments': {'current': '10', 'required': '12', 'percentage': 83},
          'daysActive': {'current': '5', 'required': '6', 'percentage': 83},
          'quests': {'current': '0', 'required': '1', 'percentage': 0},
          'updates': {'current': '0', 'required': '0', 'percentage': 100},
          'projects': {'current': '0', 'required': '0', 'percentage': 100},
        },
      };
    }
    throw ApiException('unexpected GET $path', statusCode: 404);
  }
}

Future<void> _pumpPage(WidgetTester tester, {FeedViewMode? mode}) async {
  SharedPreferences.setMockInitialValues({
    if (mode != null) 'feed_view_mode': mode.name,
  });
  final viewMode = FeedViewModeStore();
  if (mode != null) await viewMode.setMode(mode);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LevelsStore(apiClient: _FakeApiClient())),
        ChangeNotifierProvider.value(value: viewMode),
      ],
      child: const MaterialApp(home: LevelsPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders five tier headers and a progress card for 15 levels',
      (tester) async {
    tester.view.physicalSize = const Size(375, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPage(tester);

    expect(find.byType(TierSectionHeader), findsNWidgets(5));
    for (final name in ['Iron', 'Jade', 'Amethyst', 'Gold', 'Ruby']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.byType(LevelProgressCard), findsOneWidget);
    expect(find.byType(LevelListItem), findsNWidgets(15));
    expect(find.byType(LevelCardItem), findsNothing);
    expect(find.text('CURRENT'), findsOneWidget);
    expect(find.text('Next: Rank 6 · Level 6'), findsOneWidget);
  });

  testWidgets('card view mode renders tiles instead of rows', (tester) async {
    tester.view.physicalSize = const Size(375, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPage(tester, mode: FeedViewMode.card);

    expect(find.byType(TierSectionHeader), findsNWidgets(5));
    expect(find.byType(LevelCardItem), findsNWidgets(15));
    expect(find.byType(LevelListItem), findsNothing);
  });

  testWidgets('tapping a locked level opens the detail sheet with criteria',
      (tester) async {
    tester.view.physicalSize = const Size(375, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPage(tester);

    await tester.tap(find.text('Rank 12'));
    await tester.pumpAndSettle();

    final sheet = find.byType(LevelDetailSheet);
    expect(sheet, findsOneWidget);
    Finder inSheet(String text) =>
        find.descendant(of: sheet, matching: find.text(text));

    expect(inSheet('LOCKED'), findsOneWidget);
    expect(inSheet('Requirements to unlock'), findsOneWidget);
    for (final label in [
      'BNP earned',
      'Comments on updates',
      'Days active',
      'Quests completed',
      'Updates published',
      'Projects created',
    ]) {
      expect(inSheet(label), findsOneWidget);
    }
    expect(inSheet('5.2K / 12K'), findsOneWidget);
    expect(inSheet('0/6 met'), findsOneWidget);
  });
}
