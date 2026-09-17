import 'package:blocnet/features/gems/presentation/pages/gem_page.dart';
import 'package:blocnet/features/gems/presentation/pages/gem_page_sources.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/share_link.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gems_fixtures.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final quietGem = gemProject(
    'g1',
    name: 'Core Mines',
    owner: admin('admin-1', username: 'ana'),
    updatesCount: 3,
    lastUpdateAt: daysAgo(19),
    reliability: const OwnerReliability(
      profileId: 'admin-1',
      standing: ReliabilityStanding.slipping,
      coverage: 0.6,
    ),
  );
  final history = [
    gemUpdate('u-old', 'g1', title: 'Testnet opened', at: daysAgo(40)),
    gemUpdate('u-new', 'g1',
        title: 'KYC opened', at: daysAgo(19), deadline: daysAgo(-2)),
    gemUpdate('u-mid', 'g1', title: 'Node sale', at: daysAgo(25)),
  ];

  Future<ProjectsStore> pumpPage(
    WidgetTester tester, {
    required GemPageSources sources,
    List<String> followed = const [],
    List<Project> storeProjects = const [],
  }) async {
    usePhone(tester);
    final projects = ProjectsStore(
      projectsRepository: FakeProjectsRepo(storeProjects),
      postsRepository: FakeUpdatesRepo(const []),
      usersRepository: FakeUsersRepo(followed),
    );
    if (storeProjects.isNotEmpty || followed.isNotEmpty) {
      await projects.refreshProjects();
    }
    final updates = UpdatesStore(
      updatesRepository: FakeUpdatesRepo(const []),
      projectsRepository: FakeProjectsRepo(const []),
    );
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: projects),
        ChangeNotifierProvider.value(value: updates),
      ],
      child: MaterialApp(
        home: GemPage(
          projectId: 'g1',
          sources: sources,
          clock: () => gemsNow,
        ),
      ),
    ));
    return projects;
  }

  GemPageSources sources({
    Future<Project?> Function(String)? project,
    Future<List<Update>> Function(String)? updates,
  }) {
    return GemPageSources(
      project: project ?? (_) async => quietGem,
      updates: updates ?? (_) async => history,
      keeper: (id) async => hunter(id,
          name: 'Ana Keeper',
          username: 'ana',
          standing: ReliabilityStanding.slipping,
          coverage: 0.6,
          gems: 5),
    );
  }

  testWidgets('loading, then the gem with its keeper and timeline',
      (tester) async {
    await pumpPage(tester, sources: sources(), followed: ['g1']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Core Mines'), findsNWidgets(2)); // bar + card
    expect(find.text('KEPT BY'), findsOneWidget);
    expect(find.text('Ana Keeper'), findsOneWidget);
    expect(find.text('SLIPPING'), findsOneWidget);
    expect(find.text('3 of 5 gems current'), findsOneWidget);
    expect(find.text('About every 3 days'), findsOneWidget);
    expect(find.text('4 of 5'), findsOneWidget);

    // Quiet: said once at the top, with Ask for a follower.
    expect(find.byKey(const ValueKey('gem-quiet-notice')), findsOneWidget);
    expect(find.text('No update for 19 days'), findsOneWidget);
    expect(find.text('Ask @ana'), findsOneWidget);

    // The timeline: newest first, with its stated deadline.
    await tester.scrollUntilVisible(find.text('Testnet opened'), 200);
    final ys = ['KYC opened', 'Node sale', 'Testnet opened']
        .map((t) => tester.getTopLeft(find.text(t)).dy)
        .toList();
    expect(ys[0], lessThan(ys[1]));
    expect(ys[1], lessThan(ys[2]));
    expect(find.byKey(const ValueKey('gem-gap')), findsOneWidget);
    expect(find.textContaining('Closes'), findsWidgets);

    // Share is real; no bookmark stub.
    expect(find.byKey(const ValueKey('gem-page-share')), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsNothing);
  });

  testWidgets('Follow works from the page', (tester) async {
    final store = await pumpPage(
      tester,
      sources: sources(),
      storeProjects: [quietGem],
    );
    await tester.pumpAndSettle();
    expect(find.text('Follow'), findsOneWidget);
    // Not followed, so no Ask.
    expect(find.text('Ask @ana'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('gem-page-follow')));
    await tester.pumpAndSettle();
    expect(store.isProjectFollowed('g1'), isTrue);
    expect(find.text('Following'), findsOneWidget);
  });

  testWidgets('a gem with no updates says so', (tester) async {
    await pumpPage(
      tester,
      sources: sources(
        project: (_) async => gemProject('g1', createdAt: daysAgo(2)),
        updates: (_) async => const [],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No updates yet'), findsWidgets);
    expect(find.byKey(const ValueKey('gem-quiet-notice')), findsNothing);
  });

  testWidgets('a failed read offers a retry', (tester) async {
    await pumpPage(
      tester,
      sources: sources(project: (_) async => throw Exception('offline')),
    );
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load this gem"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('a failed timeline read offers a retry', (tester) async {
    await pumpPage(
      tester,
      sources: sources(updates: (_) async => throw Exception('offline')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text("Couldn't load updates"), 200);
    expect(find.text("Couldn't load updates"), findsOneWidget);
  });

  testWidgets('375px: long names and tags do not overflow', (tester) async {
    await pumpPage(
      tester,
      followed: ['g1'],
      sources: sources(
        project: (_) async => gemProject(
          'g1',
          name: 'A Very Long Gem Name That Keeps Going Past The Phone Edge',
          tag: 'Binance Smart Chain Network',
          categories: const ['Airdrop campaign', 'Mining', 'Launchpad'],
          owner: admin('admin-1',
              name: 'Somebody With A Very Long Display Name',
              username: 'a_really_long_hunter_handle_2026'),
          followers: 123456,
          updatesCount: 9999,
          lastUpdateAt: daysAgo(30),
          reliability: const OwnerReliability(
            profileId: 'admin-1',
            standing: ReliabilityStanding.quiet,
            coverage: 0.1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gem-keeper-card')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('share links open the gem path through blocnet.app', () {
    expect(
      blocnetShareLink('/projects/gem_1'),
      'https://blocnet.app/open?path=%2Fprojects%2Fgem_1',
    );
  });
}
