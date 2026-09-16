import 'package:blocnet/features/mining/data/mine_boost.dart';
import 'package:blocnet/features/mining/data/mine_cycle_phase.dart';
import 'package:blocnet/features/mining/data/mine_cycle_view.dart';
import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/widgets/cycle/mine_cycle_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mine_fixtures.dart';

MineCycleView _view(MiningSnapshot snapshot, DateTime now, {int friends = 0}) {
  final phase = MineCycleClock.resolve(
    snapshot: snapshot,
    isLoading: false,
    loadError: null,
    now: now,
  );
  return MineCycleView.resolve(
    phase: phase,
    snapshot: snapshot,
    activeFriends: friends,
    now: now,
  );
}

void main() {
  group('phase', () {
    test('no snapshot is loading, or an error once a load failed', () {
      MineCyclePhase resolve({bool loading = false, String? error}) =>
          MineCycleClock.resolve(
            snapshot: null,
            isLoading: loading,
            loadError: error,
            now: runningNow,
          );
      expect(resolve(), MineCyclePhase.loading);
      expect(resolve(loading: true, error: 'x'), MineCyclePhase.loading);
      expect(resolve(error: 'offline'), MineCyclePhase.loadError);
    });

    test('claimable flips to closing soon at six hours left', () {
      final snapshot = mineSnapshot(session: claimableSession());
      MineCyclePhase at(DateTime now) => MineCycleClock.resolve(
            snapshot: snapshot,
            isLoading: false,
            loadError: null,
            now: now,
          );
      final deadline = claimableEnd.add(const Duration(hours: 48));
      expect(at(readyNow), MineCyclePhase.ready);
      expect(
        at(deadline.subtract(const Duration(hours: 6, minutes: 1))),
        MineCyclePhase.ready,
      );
      expect(
        at(deadline.subtract(const Duration(hours: 6))),
        MineCyclePhase.closingSoon,
      );
    });

    test('paused wins over idle and running, never over a claim', () {
      MineCyclePhase at(Map<String, dynamic> session) => MineCycleClock.resolve(
            snapshot: mineSnapshot(session: session, enabled: false),
            isLoading: false,
            loadError: null,
            now: readyNow,
          );
      expect(at(idleSession()), MineCyclePhase.paused);
      expect(at(runningSession()), MineCyclePhase.paused);
      expect(at(claimableSession()), MineCyclePhase.ready);
    });
  });

  group('copy and ring per state', () {
    test('1 · idle, first visit', () {
      final view = _view(mineSnapshot(balance: 0, lifetime: 0), runningNow);
      expect(view.pill, 'NOT MINING');
      expect(view.rightLabel, 'Cycle · 24h');
      expect(view.whenBold + view.whenMuted, 'Start mining · 120 BNP a day');
      expect(view.ringFraction, 0);
      expect(view.centerNumber, isNull);
      expect(view.centerUnit, '0 BNP');
      expect([view.sideTop, view.sideBottom], ['5 BNP/hr', 'No boost yet']);
      expect(view.buttonLabel, 'Start mining');
      expect(view.showNotify, isFalse);
    });

    test('2 · running, hour 9 of 24', () {
      final view = _view(
        mineSnapshot(session: runningSession()),
        runningNow,
      );
      expect(view.pill, 'MINING');
      expect(view.rightLabel, 'Hour 9 of 24');
      expect(
        view.whenBold + view.whenMuted,
        'Ready tomorrow at 09:20 · 15h left',
      );
      expect(view.ringFraction, closeTo(9 / 24, 0.001));
      expect(view.centerNumber, '49');
      expect(view.centerUnit, 'of 132 BNP');
      expect(view.sideBottom, '+10% from 2 friends');
      expect(view.buttonLabel, isNull, reason: 'no disabled button');
      expect(view.showNotify, isTrue);
    });

    test('3 · ready, 30 hours left', () {
      final view = _view(mineSnapshot(session: claimableSession()), readyNow);
      expect(view.pill, 'READY TO CLAIM');
      expect(view.rightLabel, 'Cycle complete');
      expect(
          view.whenBold + view.whenMuted, 'Ready to claim · expires Fri 15:20');
      expect(view.ringFraction, 1);
      expect([view.centerNumber, view.centerUnit], ['132', 'BNP']);
      expect(view.buttonLabel, 'Claim 132 BNP');
      expect(view.note, 'Claiming starts your next cycle.');
      expect(view.isAmber, isFalse);
      expect(view.showNotify, isFalse);
    });

    test('4 · closing soon, 3 hours left', () {
      final view = _view(mineSnapshot(session: claimableSession()), soonNow);
      expect(view.pill, 'CLOSING SOON');
      expect(view.rightLabel, 'Claim window');
      expect(view.whenBold + view.whenMuted, 'Expires in 3h · today at 15:20');
      expect(view.ringFraction, closeTo(3 / 48, 0.001));
      expect([
        view.sideTop,
        view.sideBottom
      ], [
        'Claim before 15:20',
        "or it's gone",
      ]);
      expect(view.buttonLabel, 'Claim 132 BNP');
      expect(view.isAmber, isTrue);
      expect(view.note, isNull);
    });

    test('6 · idle after an expiry: boosted day, notify row', () {
      final view = _view(
        mineSnapshot(lastExpiredCycle: {'sessionId': 'lost'}),
        runningNow,
        friends: 2,
      );
      expect(view.whenBold + view.whenMuted, 'Start mining · 132 BNP a day');
      expect(view.sideBottom, '+10% from 2 friends');
      expect(view.showNotify, isTrue);
    });

    test('7 · paused', () {
      final view = _view(mineSnapshot(enabled: false), runningNow);
      expect(view.pill, 'PAUSED BY BLOCNET');
      expect(view.rightLabel, 'All members');
      expect(
        view.whenBold + view.whenMuted,
        'Mining is paused · your balance is safe',
      );
      expect(view.centerUnit, 'Paused');
      expect(view.ringFraction, 0);
      expect([view.sideTop, view.sideBottom, view.buttonLabel],
          everyElement(isNull));
      expect(view.showNotify, isFalse);
    });

    test('the summary label names stated times, not the countdown', () {
      final running =
          _view(mineSnapshot(session: runningSession()), runningNow);
      expect(
        mineCycleSemanticsLabel(running),
        'Mining, ready tomorrow at 09:20, 49 of 132 BNP',
      );
      final soon = _view(mineSnapshot(session: claimableSession()), soonNow);
      expect(
        mineCycleSemanticsLabel(soon),
        'Closing soon, 132 BNP, expires today at 15:20',
      );
    });
  });

  group('boost', () {
    final config = mineSnapshot().config;

    test('is capped and drawn as one segment per friend', () {
      final two = MineBoost.forFriends(config, 2);
      expect(two.percent, '+10%');
      expect(two.segments, 20);
      expect(two.filledSegments, 2);
      expect(two.rowTitle, '2 active friends · +10%');
      expect(two.boostCaption, '2 active friends · max +100%');
      expect(two.pointsPerCycle(), 132);

      final many = MineBoost.forFriends(config, 30);
      expect(many.percent, '+100%');
      expect(many.filledSegments, 20);
    });

    test('singular friend and the next friend value', () {
      final none = MineBoost.forFriends(config, 0);
      expect(none.sideLine, 'No boost yet');
      expect(none.pointsPerCycleWithOneMore(), 126);
      expect(MineBoost.forFriends(config, 1).sideLine, '+5% from 1 friend');
    });
  });

  test('short durations round up and switch to minutes under an hour', () {
    expect(
        MineFormat.shortDuration(const Duration(hours: 14, minutes: 1)), '15h');
    expect(MineFormat.shortDuration(const Duration(minutes: 40)), '40m');
    expect(MineFormat.shortDuration(Duration.zero), '0m');
  });
}
