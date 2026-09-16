import 'package:blocnet/features/mining/data/mining_expiry_copy.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/data/repositories/mining_api_repository.dart';
import 'package:blocnet/features/mining/presentation/pages/mining_screen.dart';
import 'package:blocnet/features/mining/presentation/widgets/mining_hero_card.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/mining_fixtures.dart';

MiningSnapshot _snapshot({
  Map<String, dynamic>? session,
  bool enabled = true,
}) {
  return MiningSnapshot.fromApi(
    miningSnapshotJson(session: session, enabled: enabled, cycleHours: 12),
  );
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

class _HeroProbe {
  int starts = 0;
  int claims = 0;
  int retries = 0;
  int cycleEnds = 0;
  DateTime now = miningAsOf;

  MiningHeroCard card({
    MiningSnapshot? snapshot,
    bool isLoading = false,
    String? loadError,
  }) {
    return MiningHeroCard(
      snapshot: snapshot,
      onStart: () => starts++,
      onClaim: () => claims++,
      isStarting: false,
      isClaiming: false,
      isLoadingSnapshot: isLoading,
      serverNow: () => now,
      loadError: loadError,
      onRetry: () => retries++,
      onCycleEnd: () => cycleEnds++,
    );
  }
}

void main() {
  group('MiningHeroCard states', () {
    testWidgets('idle offers Start and uses config.cycleHours', (tester) async {
      final probe = _HeroProbe();
      await tester.pumpWidget(_host(probe.card(snapshot: _snapshot())));

      expect(find.text('IDLE'), findsOneWidget);
      expect(find.text('Start Mining'), findsOneWidget);
      await _tapText(tester, 'Start Mining');
      expect(probe.starts, 1);
      // The invented "Mining Power" tile is gone; the claim window is real.
      expect(find.text('Mining Power'), findsNothing);
      expect(find.text('Claim window'), findsOneWidget);
      expect(find.text('48h'), findsOneWidget);
    });

    testWidgets('running counts down on server time, no Start or Claim',
        (tester) async {
      final probe = _HeroProbe();
      final snapshot = _snapshot(session: runningSessionJson());
      await tester.pumpWidget(_host(probe.card(snapshot: snapshot)));

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('Claim in 01:00:00'), findsOneWidget);
      expect(find.text('Start Mining'), findsNothing);
      expect(find.text('Claim Rewards'), findsNothing);
      // A running session omits cycleHours: the config's 12 is used, not 24.
      expect(find.textContaining('Claim after 12h'), findsOneWidget);

      probe.now = miningAsOf.add(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Claim in 59:55'), findsOneWidget);
      expect(probe.cycleEnds, 0);

      probe.now = miningAsOf.add(const Duration(hours: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Wrapping up this cycle...'), findsOneWidget);
      expect(probe.cycleEnds, greaterThan(0));
    });

    testWidgets('claimable offers Claim', (tester) async {
      final probe = _HeroProbe();
      final snapshot = _snapshot(
        session: runningSessionJson(
          status: 'claimable',
          endsAt: miningAsOf.subtract(const Duration(hours: 1)),
        ),
      );
      await tester.pumpWidget(_host(probe.card(snapshot: snapshot)));

      expect(find.text('CLAIM READY'), findsOneWidget);
      await _tapText(tester, 'Claim Rewards');
      expect(probe.claims, 1);
      expect(find.text('Start Mining'), findsNothing);
    });

    testWidgets('paused hides Start and says so', (tester) async {
      final probe = _HeroProbe();
      await tester.pumpWidget(
        _host(probe.card(snapshot: _snapshot(enabled: false))),
      );

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('Mining is paused'), findsWidgets);
      expect(find.text('Start Mining'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('paused still lets a finished cycle be claimed',
        (tester) async {
      final probe = _HeroProbe();
      final snapshot = _snapshot(
        enabled: false,
        session: runningSessionJson(status: 'claimable'),
      );
      await tester.pumpWidget(_host(probe.card(snapshot: snapshot)));

      expect(find.text('Mining is paused'), findsOneWidget);
      expect(find.textContaining('can still be claimed'), findsOneWidget);
      await _tapText(tester, 'Claim Rewards');
      expect(probe.claims, 1);
    });

    testWidgets('first-load failure shows error and retry, not an idle card',
        (tester) async {
      final probe = _HeroProbe();
      await tester.pumpWidget(
        _host(probe.card(loadError: 'Network is unreachable')),
      );

      expect(find.text("Couldn't load your mining status"), findsOneWidget);
      expect(find.text('Network is unreachable'), findsOneWidget);
      expect(find.text('Start Mining'), findsNothing);
      expect(find.textContaining('BNP'), findsNothing);
      await _tapText(tester, 'Retry');
      expect(probe.retries, 1);
    });

    testWidgets('first load in flight shows no made-up numbers',
        (tester) async {
      final probe = _HeroProbe();
      await tester.pumpWidget(
        _host(probe.card(isLoading: true, loadError: 'old failure')),
      );

      expect(find.text('Checking your mining status...'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(find.textContaining('BNP'), findsNothing);
    });
  });

  group('MiningHeroCard clock', () {
    testWidgets('does no work while its tab is hidden', (tester) async {
      final probe = _HeroProbe()
        ..now = miningAsOf.add(const Duration(hours: 2));
      final snapshot = _snapshot(session: runningSessionJson());

      Widget tab(bool visible) => _host(
            Visibility.maintain(
              visible: visible,
              child: probe.card(snapshot: snapshot),
            ),
          );

      await tester.pumpWidget(tab(false));
      await tester.pump(const Duration(seconds: 3));
      expect(probe.cycleEnds, 0);

      await tester.pumpWidget(tab(true));
      await tester.pump(const Duration(seconds: 1));
      expect(probe.cycleEnds, greaterThan(0));
    });

    testWidgets('stops when tickers are muted', (tester) async {
      final probe = _HeroProbe()
        ..now = miningAsOf.add(const Duration(hours: 2));
      final snapshot = _snapshot(session: runningSessionJson());

      await tester.pumpWidget(
        _host(TickerMode(
          enabled: false,
          child: probe.card(snapshot: snapshot),
        )),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(probe.cycleEnds, 0);
    });
  });

  group('MiningScreen', () {
    Future<MiningStore> pumpScreen(
      WidgetTester tester,
      _ScreenRepo repo,
    ) async {
      final store = MiningStore(repository: repo);
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider<MiningStore>.value(
          value: store,
          child: const MaterialApp(home: Scaffold(body: MiningScreen())),
        ),
      );
      await tester.pump();
      await tester.pump();
      return store;
    }

    testWidgets('shows the expired notice for a fresh forfeit',
        (tester) async {
      final repo = _ScreenRepo(
        miningSnapshotJson(
          lastExpiredCycle: {
            'sessionId': 'lost-1',
            'expiredAt': miningAsOf.toIso8601String(),
            'forfeitedPoints': 120,
          },
        ),
      );
      await pumpScreen(tester, repo);

      expect(find.text(MiningExpiryCopy.noticeTitle), findsOneWidget);
      expect(find.text('Start Mining'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pump();
      expect(find.text(MiningExpiryCopy.noticeTitle), findsNothing);
    });

    testWidgets('a failed first load retries into the real hero',
        (tester) async {
      final repo = _ScreenRepo(miningSnapshotJson())
        ..failSnapshot = true;
      await pumpScreen(tester, repo);

      expect(find.text("Couldn't load your mining status"), findsOneWidget);
      expect(find.text('Start Mining'), findsNothing);

      repo.failSnapshot = false;
      await _tapText(tester, 'Retry');
      await tester.pump();
      await tester.pump();

      expect(find.text('Start Mining'), findsOneWidget);
      expect(repo.snapshotCalls, 2);
    });
  });
}

class _ScreenRepo extends MiningApiRepository {
  _ScreenRepo(this.body);

  final Map<String, dynamic> body;
  bool failSnapshot = false;
  int snapshotCalls = 0;

  @override
  Future<MiningSnapshot?> fetchMiningSnapshot() async {
    snapshotCalls++;
    if (failSnapshot) {
      throw ApiException('Network is unreachable');
    }
    return MiningSnapshot.fromApi(body);
  }

  @override
  Future<ReferralSummaryModel?> fetchReferralSummary() async => null;

  @override
  Future<MiningLeaderboardResponse?> fetchLeaderboard({
    int limit = 20,
    int offset = 0,
  }) async =>
      null;
}
