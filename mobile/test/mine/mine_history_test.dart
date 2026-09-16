import 'package:blocnet/features/mining/data/mine_history.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/pages/mining_hourly_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mine_fixtures.dart';
import '../support/mine_harness.dart';

List<Map<String, dynamic>> _cycle(
  String id,
  DateTime start,
  String status, {
  int hours = 24,
}) =>
    [
      for (var i = 0; i < hours; i++)
        checkpoint(
          sessionId: id,
          hourStart: start.add(Duration(hours: i)),
          status: status,
        ),
    ];

/// The design's state 10: a live cycle, a claimed one, an expired one.
List<Map<String, dynamic>> _designHistory() => [
      ..._cycle('lost', DateTime(2026, 9, 14, 0), 'expired', hours: 20),
      ..._cycle('won', DateTime(2026, 9, 15, 0), 'claimed'),
      ..._cycle('run-1', DateTime(2026, 9, 16, 7), 'unclaimed', hours: 3),
    ];

List<MiningHourlyCheckpointModel> _models(List<Map<String, dynamic>> rows) =>
    rows.map(MiningHourlyCheckpointModel.fromApi).toList();

void main() {
  group('MineHistory.group', () {
    final groups = MineHistory.group(
      _models(_designHistory()),
      currentSessionId: 'run-1',
    );

    test('one group per cycle, newest cycle and newest hour first', () {
      expect(groups.map((g) => g.sessionId), ['run-1', 'won', 'lost']);
      expect(groups.first.hours.first.hourStartAt, DateTime(2026, 9, 16, 9));
      expect(groups.first.hours.last.hourStartAt, DateTime(2026, 9, 16, 7));
    });

    test('headers state the outcome', () {
      expect(groups.map((g) => g.title), [
        '16 Sep · now',
        '15 Sep · 132 BNP',
        '14 Sep · 0 BNP',
      ]);
      expect(groups.map((g) => g.pill), ['NOT CLAIMED', 'CLAIMED', 'EXPIRED']);
      expect(
        groups.first.hours.map(MineHistory.hourState).toSet(),
        {'Waiting'},
      );
    });

    test('summary for the Mine row', () {
      expect(MineHistory.summary(groups), '1 claimed · 1 expired');
      expect(
        MineHistory.summary(
          MineHistory.group(_models([
            ..._cycle('a', DateTime(2026, 9, 14), 'claimed'),
            ..._cycle('b', DateTime(2026, 9, 15), 'claimed'),
          ])),
        ),
        '2 claimed · 264 BNP',
      );
      expect(
        MineHistory.summary(
          MineHistory.group(
            _models(_cycle('c', runningStart, 'unclaimed', hours: 2)),
            currentSessionId: 'c',
          ),
        ),
        '11 BNP so far',
      );
      expect(MineHistory.summary(const []), isNull);
    });
  });

  testWidgets('10 · headers then hours, expired hours struck through',
      (tester) async {
    usePhone(tester, height: 4000);
    final repo = FakeMineRepo(
      mineSnapshotJson(session: runningSession(), history: _designHistory()),
    );
    await tester.pumpWidget(
      mineHost(
        store: mineStore(repo, now: runningNow),
        settings: await loadedSettings(FakeNotificationsRepo()),
        child: const MiningHourlyHistoryScreen(),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Hourly history'), findsOneWidget);
    expectTopToBottom(tester, [
      find.text('16 SEP · NOW'),
      find.text('NOT CLAIMED'),
      find.text('09:00').first,
      find.text('15 SEP · 132 BNP'),
      find.text('CLAIMED'),
      find.text('14 SEP · 0 BNP'),
      find.text('EXPIRED'),
    ]);
    expect(find.text('Waiting'), findsNWidgets(3));
    expect(find.text('Claimed'), findsNWidgets(24));
    expect(find.text('Expired'), findsNWidgets(20));
    expect(find.text('5.5 BNP'), findsNWidgets(47));

    final struck = tester
        .widgetList<Text>(find.text('5.5 BNP'))
        .where((t) => t.style?.decoration == TextDecoration.lineThrough);
    expect(struck.length, 20);
  });
}
