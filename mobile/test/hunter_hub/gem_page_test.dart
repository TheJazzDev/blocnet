import 'package:blocnet/features/hunter/data/models/hunter_gem_detail_model.dart';
import 'package:blocnet/features/hunter/data/repositories/hunter_reliability_api_repository.dart';
import 'package:blocnet/features/hunter/presentation/pages/hunter_gem_screen.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/hub_fab.dart';
import 'package:blocnet/features/main/presentation/widgets/space_bottom_nav.dart';
import 'package:blocnet/features/projects/data/repositories/project_proposals_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'hub_fixtures.dart';
import 'hub_harness.dart';

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();
}

/// A store that already holds one gem page and never goes to the network.
class _GemStore extends HunterBoardStore {
  _GemStore(this.detail)
      : super(
          repository: HunterReliabilityApiRepository(
            apiClient: ApiClient(httpClient: _NoopHttpClient()),
          ),
          proposalsRepository: ProjectProposalsApiRepository(
            apiClient: ApiClient(httpClient: _NoopHttpClient()),
          ),
        );

  final HunterGemDetail detail;
  int loads = 0;

  @override
  HunterGemDetail? gemFor(String projectId) =>
      projectId == detail.gem.projectId ? detail : null;

  @override
  Future<void> loadGem(String projectId) async => loads++;
}

Future<_GemStore> _pumpGemPage(
  WidgetTester tester,
  HunterGemDetail detail, {
  double width = 375,
}) async {
  usePhone(tester, width);
  final store = _GemStore(detail);
  await tester.pumpWidget(
    ChangeNotifierProvider<HunterBoardStore>.value(
      value: store,
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: HunterGemScreen(initialGem: detail.gem, clock: () => hubNow),
      ),
    ),
  );
  await tester.pump();
  return store;
}

void main() {
  for (final width in hubWidths) {
    group('@${width.toInt()}', () {
      testWidgets('state 6 · the gem page, opened from a quiet gem',
          (tester) async {
        final store = await _pumpGemPage(tester, haloDetail(), width: width);
        expect(tester.takeException(), isNull);
        expect(store.loads, 1, reason: 'loads its own payload on open');

        expectVerticalOrder(tester, [
          find.text('Your gem'),
          byKey('gem-header'),
          byKey('gem-wait'),
          byKey('gem-report'),
          byKey('gem-post'),
          byKey('gem-gap'),
          byKey('gem-event-e1'),
          byKey('gem-event-e2'),
          byKey('gem-event-e3'),
        ]);
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
        expect(find.byIcon(Icons.more_horiz_rounded), findsWidgets);

        final header = byKey('gem-header');
        expect(inside(header, find.text('HP')), findsOneWidget);
        expect(inside(header, find.text('Halo Points')), findsOneWidget);
        expect(inside(header, find.text('ETHEREUM')), findsOneWidget);
        expect(inside(header, find.text('4,730 following')), findsOneWidget);
        expect(inside(header, find.text('QUIET')), findsOneWidget);

        expect(find.text('31 members are waiting'), findsOneWidget);
        expect(
          find.text('They asked for an update this week. One post clears all '
              "of them — they're notified the moment you publish."),
          findsOneWidget,
        );
        expect(inside(byKey('gem-report'), find.text('2 reports')),
            findsOneWidget);
        expect(find.text('Unmaintained'), findsOneWidget);
        expect(inside(byKey('gem-post'), find.text('Post update')),
            findsOneWidget);

        // D4: no hand-over until handover invites exist.
        expect(find.text('Hand over'), findsNothing);

        expect(find.text('19 days without an update'), findsOneWidget);
        final newest = byKey('gem-event-e1');
        expect(inside(newest, find.text('20 AUG · HIGH')), findsOneWidget);
        expect(inside(newest, find.text('Edit')), findsOneWidget);
        expect(
          inside(
              newest, find.text('412 likes · 38 comments · 2,100 BNP tipped')),
          findsOneWidget,
        );
        expect(inside(byKey('gem-event-e2'), find.text('6 AUG · MEDIUM')),
            findsOneWidget);
        expect(
          inside(byKey('gem-event-e2'), find.text('156 likes · 11 comments')),
          findsOneWidget,
          reason: 'tips omitted at zero',
        );
        expect(inside(byKey('gem-event-e3'), find.text('28 JUL · LOW')),
            findsOneWidget);
        expect(find.text('Edit'), findsNWidgets(3));

        // Bottom bar with Hub on, and no FAB.
        final nav = tester.widget<SpaceBottomNav>(find.byType(SpaceBottomNav));
        expect(nav.space, NavSpace.hunter);
        expect(nav.currentIndex, 2);
        expect(find.text('Hub'), findsOneWidget);
        expect(find.byType(HubFab), findsNothing);
        expect(find.byType(FloatingActionButton), findsNothing);

        // The menu carries View as member and nothing else.
        await tester.tap(byKey('gem-page-menu'));
        await tester.pumpAndSettle();
        expect(find.text('View as member'), findsOneWidget);
        expect(find.text('Hand over'), findsNothing);
      });

      testWidgets('wait and report cards are hidden at zero', (tester) async {
        await _pumpGemPage(tester, haloDetail(waiting: 0, reports: 0),
            width: width);
        expect(tester.takeException(), isNull);
        expect(byKey('gem-wait'), findsNothing);
        expect(byKey('gem-report'), findsNothing);
        expect(find.textContaining('waiting'), findsNothing);
        expectVerticalOrder(tester, [
          byKey('gem-header'),
          byKey('gem-post'),
          byKey('gem-gap'),
        ]);
      });

      testWidgets('a gem that is not quiet draws no gap', (tester) async {
        final detail = HunterGemDetail(
          gem: terraVault(),
          updates: haloDetail().updates,
          gapDays: null,
        );
        await _pumpGemPage(tester, detail, width: width);
        expect(tester.takeException(), isNull);
        expect(byKey('gem-gap'), findsNothing);
        expect(inside(byKey('gem-header'), find.text('DUE')), findsOneWidget);
        expect(byKey('gem-timeline'), findsOneWidget);
      });
    });
  }

  group('bottom bar', () {
    for (final width in hubWidths) {
      for (final space in NavSpace.values) {
        testWidgets('${space.name} fits six labelled tabs at $width',
            (tester) async {
          usePhone(tester, width);
          final taps = <int>[];
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              bottomNavigationBar: SpaceBottomNav(
                space: space,
                currentIndex: 2,
                onTap: taps.add,
              ),
            ),
          ));
          expect(tester.takeException(), isNull);
          final third = switch (space) {
            NavSpace.user => 'Community',
            NavSpace.hunter => 'Hub',
            NavSpace.moderation => 'Moderate',
          };
          final labels = ['Home', 'Gems', third, 'Mine', 'Wallet', 'Profile'];
          double? lastX;
          for (final label in labels) {
            final text = tester.widget<Text>(find.text(label));
            expect(text.style?.fontSize, 11);
            final x = tester.getCenter(find.text(label)).dx;
            if (lastX != null) expect(x, greaterThan(lastX));
            lastX = x;
          }
          final active = tester.widget<Text>(find.text(third));
          expect(active.style?.color, SpaceBottomNav.accentFor(space));
          final idle = tester.widget<Text>(find.text('Home'));
          expect(idle.style?.color, isNot(SpaceBottomNav.accentFor(space)));
          await tester.tap(find.text('Wallet'));
          expect(taps, [4]);
        });
      }
    }

    test('icons follow the spec', () {
      final hunter = SpaceBottomNav.tabsFor(NavSpace.hunter);
      expect(hunter.map((t) => t.activeIcon), [
        Icons.home_rounded,
        Icons.diamond_rounded,
        Icons.shield_rounded,
        Icons.bolt_rounded,
        Icons.account_balance_wallet_rounded,
        Icons.person_rounded,
      ]);
      expect(
          SpaceBottomNav.tabsFor(NavSpace.user)[2].icon, Icons.groups_outlined);
      expect(SpaceBottomNav.tabsFor(NavSpace.moderation)[2].activeIcon,
          Icons.gavel_rounded);
    });
  });

  group('Hub FAB', () {
    testWidgets('posts an update, or submits a gem on day one', (tester) async {
      usePhone(tester, 375);
      var posts = 0;
      var submits = 0;
      Widget fab(bool dayOne) => MaterialApp(
            home: Scaffold(
              floatingActionButton: HubFab(
                dayOne: dayOne,
                onPostUpdate: () => posts++,
                onSubmitGem: () => submits++,
              ),
            ),
          );
      await tester.pumpWidget(fab(false));
      expect(find.text('Post update'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      await tester.tap(find.text('Post update'));
      expect(posts, 1);

      await tester.pumpWidget(fab(true));
      expect(find.text('Submit a gem'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      await tester.tap(find.text('Submit a gem'));
      expect(submits, 1);
      expect(tester.getSize(find.byKey(const ValueKey('hub-fab'))).height, 56);
    });
  });
}
