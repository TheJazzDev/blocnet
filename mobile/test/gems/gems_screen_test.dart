import 'package:blocnet/features/gems/domain/gems_tab.dart';
import 'package:blocnet/features/gems/presentation/gems_navigation.dart';
import 'package:blocnet/features/gems/presentation/pages/gems_screen.dart';
import 'package:blocnet/features/hunter/data/models/hunter_leaderboard_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/services/gems/hunter_leaderboard_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gems_fixtures.dart';

const _long =
    'A Very Long Gem Name That Keeps Going Past The Edge Of The Phone';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final projects = [
    gemProject(
      'g1',
      name: _long,
      tag: 'Binance Smart Chain Network',
      categories: const ['Airdrop campaign', 'Mining', 'Launchpad'],
      owner: admin('admin-1',
          name: 'Somebody With A Very Long Display Name',
          username: 'a_really_long_hunter_handle_2026'),
      followers: 123456,
      updatesCount: 9999,
      reliability: const OwnerReliability(
        profileId: 'admin-1',
        standing: ReliabilityStanding.slipping,
        coverage: 0.5,
      ),
    ),
    gemProject('g2',
        name: 'Sol Drop', tag: 'Solana', lastUpdateAt: daysAgo(30)),
  ];
  final updates = [
    gemUpdate('u1', 'g1',
        title: 'An update title long enough to wrap twice on a small phone',
        at: daysAgo(1),
        deadline: daysAgo(-1)),
  ];

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Project>? gems,
    List<Update>? feed,
    List<String> followed = const ['g1', 'g2'],
    bool failProjects = false,
  }) async {
    usePhone(tester);
    final projectsStore = ProjectsStore(
      projectsRepository:
          FakeProjectsRepo(gems ?? projects, fail: failProjects),
      postsRepository: FakeUpdatesRepo(feed ?? updates),
      usersRepository: FakeUsersRepo(followed),
    );
    final updatesStore = UpdatesStore(
      updatesRepository: FakeUpdatesRepo(feed ?? updates),
      projectsRepository: FakeProjectsRepo(gems ?? projects),
    );
    final leaderboard = HunterLeaderboardStore(
      fetch: ({int limit = 20, cursor}) async => HunterLeaderboardPage(
        entries: [
          ranked(
              1,
              hunter('admin-1',
                  name: 'Somebody With A Very Long Display Name',
                  username: 'a_really_long_hunter_handle_2026',
                  standing: ReliabilityStanding.slipping,
                  followers: 9876543)),
        ],
      ),
    );
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: projectsStore),
        ChangeNotifierProvider.value(value: updatesStore),
      ],
      child: MaterialApp(
        home: GemsScreen(leaderboard: leaderboard, clock: () => gemsNow),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('375px: every view renders long content without overflow',
      (tester) async {
    await pumpScreen(tester);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.byKey(const ValueKey('gem-card-g1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gems-tab-board')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('board-row-g1')), findsOneWidget);
    expect(find.byKey(const ValueKey('quiet-pill')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gems-tab-hunters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hunter-row-admin-1')), findsOneWidget);
    // Keeps a gem the member follows.
    expect(find.byKey(const ValueKey('keeps-your-gems')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GemsNavigation opens a chosen view', (tester) async {
    await pumpScreen(tester);
    expect(find.byKey(const ValueKey('gem-card-g1')), findsOneWidget);

    GemsNavigation.requests.push(GemsTab.board);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('board-row-g1')), findsOneWidget);
    expect(GemsNavigation.requests.take(), isNull);
  });

  testWidgets('a pending request picks the first view', (tester) async {
    GemsNavigation.requests.push(GemsTab.hunters);
    await pumpScreen(tester);
    expect(find.text('RANKED BY RELIABILITY'), findsOneWidget);
  });

  testWidgets('empty board sends the member to Discover', (tester) async {
    await pumpScreen(tester, followed: const []);
    await tester.tap(find.byKey(const ValueKey('gems-tab-board')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discover gems'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gem-card-g1')), findsOneWidget);
  });

  testWidgets('a failed read shows the error on Discover', (tester) async {
    await pumpScreen(tester, failProjects: true);
    expect(find.text("Couldn't load gems"), findsOneWidget);
  });
}
