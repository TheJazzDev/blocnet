import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/widgets/cycle/mine_cycle_card.dart';
import 'package:blocnet/features/mining/presentation/widgets/cycle/mine_progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mine_fixtures.dart';
import '../support/mine_harness.dart';

class _Probe {
  _Probe(this.now);

  DateTime now;
  int starts = 0;
  int claims = 0;
  int cycleEnds = 0;

  MineCycleCard card(MiningSnapshot snapshot, {int friends = 0}) {
    return MineCycleCard(
      snapshot: snapshot,
      activeFriends: friends,
      serverNow: () => now,
      onStart: () => starts++,
      onClaim: () => claims++,
      onCycleEnd: () => cycleEnds++,
    );
  }
}

Future<void> _pump(WidgetTester tester, Widget card) async {
  usePhone(tester, height: 900);
  final settings = await loadedSettings(FakeNotificationsRepo());
  await tester.pumpWidget(
    mineHost(
      store: mineStore(FakeMineRepo(null)),
      settings: settings,
      child: SingleChildScrollView(child: card),
    ),
  );
}

double _ring(WidgetTester tester) {
  final paint =
      tester.widget<CustomPaint>(find.byKey(const ValueKey('mine-ring')));
  return (paint.painter! as MineRingPainter).fraction;
}

void main() {
  testWidgets('1 · idle: pill, when, ring, side, Start mining — in order',
      (tester) async {
    final probe = _Probe(runningNow);
    await _pump(tester, probe.card(mineSnapshot(balance: 0, lifetime: 0)));

    expectTopToBottom(tester, [
      find.text('NOT MINING'),
      find.text('Start mining · 120 BNP a day'),
      find.text('0 BNP'),
      find.text('Start mining'),
    ]);
    expect(find.text('CYCLE · 24H'), findsOneWidget);
    expect(find.text('5 BNP/hr'), findsOneWidget);
    expect(find.text('No boost yet'), findsOneWidget);
    expect(find.text("Notify me when it's ready"), findsNothing);
    expect(_ring(tester), 0);

    await tester.tap(find.text('Start mining'));
    expect(probe.starts, 1);
  });

  testWidgets('2 · running: no button, notify row, ring at 9 of 24',
      (tester) async {
    final probe = _Probe(runningNow);
    await _pump(tester, probe.card(mineSnapshot(session: runningSession())));

    expectTopToBottom(tester, [
      find.text('MINING'),
      find.text('Ready tomorrow at 09:20 · 15h left'),
      find.text('49'),
      find.text('of 132 BNP'),
      find.text("Notify me when it's ready"),
    ]);
    expect(find.text('HOUR 9 OF 24'), findsOneWidget);
    expect(find.text('+10% from 2 friends'), findsOneWidget);
    expect(find.byKey(const ValueKey('mine-primary')), findsNothing);
    expect(find.textContaining('Claim'), findsNothing);
    expect(_ring(tester), closeTo(0.375, 0.001));
  });

  testWidgets('3 · ready: full ring, Claim with its amount, then the note',
      (tester) async {
    final probe = _Probe(readyNow);
    await _pump(tester, probe.card(mineSnapshot(session: claimableSession())));

    expectTopToBottom(tester, [
      find.text('READY TO CLAIM'),
      find.text('Ready to claim · expires Fri 15:20'),
      find.text('132'),
      find.text('Claim 132 BNP'),
      find.text('Claiming starts your next cycle.'),
    ]);
    expect(find.text('CYCLE COMPLETE'), findsOneWidget);
    expect(_ring(tester), 1);
    expect(find.text("Notify me when it's ready"), findsNothing);

    await tester.tap(find.text('Claim 132 BNP'));
    expect(probe.claims, 1);
  });

  testWidgets('4 · closing soon: amber ring drains, amber Claim, no note',
      (tester) async {
    final probe = _Probe(soonNow);
    await _pump(tester, probe.card(mineSnapshot(session: claimableSession())));

    expectTopToBottom(tester, [
      find.text('CLOSING SOON'),
      find.text('Expires in 3h · today at 15:20'),
      find.text('Claim before 15:20'),
      find.text("or it's gone"),
      find.text('Claim 132 BNP'),
    ]);
    expect(find.text('CLAIM WINDOW'), findsOneWidget);
    expect(_ring(tester), closeTo(3 / 48, 0.001));
    final painter = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('mine-ring')))
        .painter! as MineRingPainter;
    expect(painter.color, const Color(0xFFF59E0B));
    expect(find.text('Claiming starts your next cycle.'), findsNothing);
  });

  testWidgets('7 · paused: no button, no side, no notify', (tester) async {
    final probe = _Probe(runningNow);
    await _pump(tester, probe.card(mineSnapshot(enabled: false)));

    expectTopToBottom(tester, [
      find.text('PAUSED BY BLOCNET'),
      find.text('Mining is paused · your balance is safe'),
      find.text('Paused'),
    ]);
    expect(find.text('ALL MEMBERS'), findsOneWidget);
    expect(find.byKey(const ValueKey('mine-primary')), findsNothing);
    expect(find.textContaining('BNP/hr'), findsNothing);
    expect(find.text("Notify me when it's ready"), findsNothing);
  });

  testWidgets('the card reads as one summary node', (tester) async {
    final semantics = tester.ensureSemantics();
    final probe = _Probe(runningNow);
    await _pump(tester, probe.card(mineSnapshot(session: runningSession())));

    expect(
      find.bySemanticsLabel('Mining, ready tomorrow at 09:20, 49 of 132 BNP'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('MINING'), findsNothing);
    expect(find.bySemanticsLabel('HOUR 9 OF 24'), findsNothing);
    semantics.dispose();
  });

  group('clock', () {
    testWidgets('refetches once the cycle ends', (tester) async {
      final probe = _Probe(runningNow);
      await _pump(tester, probe.card(mineSnapshot(session: runningSession())));
      await tester.pump(const Duration(seconds: 1));
      expect(probe.cycleEnds, 0);

      probe.now = runningStart.add(const Duration(hours: 24, seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(probe.cycleEnds, greaterThan(0));
      expect(find.text('Ready today at 09:20 · now'), findsOneWidget);
    });

    testWidgets('does no work while its tab is hidden', (tester) async {
      final probe = _Probe(runningStart.add(const Duration(hours: 25)));
      final snapshot = mineSnapshot(session: runningSession());
      usePhone(tester, height: 900);
      final settings = await loadedSettings(FakeNotificationsRepo());
      Widget tab(bool visible) => mineHost(
            store: mineStore(FakeMineRepo(null)),
            settings: settings,
            child: Visibility.maintain(
              visible: visible,
              child: probe.card(snapshot),
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
      final probe = _Probe(runningStart.add(const Duration(hours: 25)));
      await _pump(
        tester,
        TickerMode(
          enabled: false,
          child: probe.card(mineSnapshot(session: runningSession())),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(probe.cycleEnds, 0);
    });

    testWidgets('reduced motion holds the glow still', (tester) async {
      final probe = _Probe(runningNow);
      usePhone(tester, height: 900);
      final settings = await loadedSettings(FakeNotificationsRepo());
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: mineHost(
            store: mineStore(FakeMineRepo(null)),
            settings: settings,
            child: probe.card(mineSnapshot(session: runningSession())),
          ),
        ),
      );
      MineRingPainter painter() => tester
          .widget<CustomPaint>(find.byKey(const ValueKey('mine-ring')))
          .painter! as MineRingPainter;
      final before = painter().glow;
      await tester.pump(const Duration(milliseconds: 600));
      expect(painter().glow, before);
    });

    testWidgets('the running glow breathes', (tester) async {
      final probe = _Probe(runningNow);
      await _pump(tester, probe.card(mineSnapshot(session: runningSession())));
      MineRingPainter painter() => tester
          .widget<CustomPaint>(find.byKey(const ValueKey('mine-ring')))
          .painter! as MineRingPainter;
      final before = painter().glow;
      await tester.pump(const Duration(milliseconds: 600));
      expect(painter().glow, isNot(before));
    });
  });
}
