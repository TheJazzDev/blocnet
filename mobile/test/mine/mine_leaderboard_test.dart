import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/pages/mining_leaderboard_screen.dart';
import 'package:blocnet/features/mining/presentation/widgets/leaderboard/mine_leaderboard_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mine_fixtures.dart';
import '../support/mine_harness.dart';

MiningLeaderboardEntry _entry(int rank, {String? userId}) =>
    MiningLeaderboardEntry.fromApi(leaderboardRow(rank, userId: userId));

FakeMineRepo _repo({bool withMe = true}) {
  return FakeMineRepo(mineSnapshotJson())
    ..leaderboardRows = [
      for (var rank = 1; rank <= 30; rank++)
        leaderboardRow(
          rank,
          status: rank.isOdd ? 'running' : 'idle',
          points: 100000 - rank,
        ),
    ]
    ..leaderboardMe = withMe
        ? {...leaderboardRow(27, points: 8412), 'isMiningNow': true}
        : null;
}

Future<void> _pump(WidgetTester tester, FakeMineRepo repo,
    {double height = 2400}) async {
  usePhone(tester, height: height);
  await tester.pumpWidget(
    mineHost(
      store: mineStore(repo, now: runningNow),
      settings: await loadedSettings(FakeNotificationsRepo()),
      child: const MiningLeaderboardScreen(),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Color? _rankColor(WidgetTester tester, String rank) =>
    tester.widget<Text>(find.text(rank).first).style?.color;

final _pinned = find.byKey(const ValueKey('mine-pinned-row'));

void main() {
  group('pin logic', () {
    final page = [for (var r = 1; r <= 10; r++) _entry(r)];

    test('no me block, no pin', () {
      expect(
        mineShouldPinMe(me: null, page: page, meRowVisible: false),
        isFalse,
      );
    });

    test('pinned while the row is on another page', () {
      expect(
        mineShouldPinMe(me: _entry(27), page: page, meRowVisible: false),
        isTrue,
      );
    });

    test('pinned only while an on-page row is scrolled away', () {
      final me = _entry(7);
      expect(mineShouldPinMe(me: me, page: page, meRowVisible: true), isFalse);
      expect(mineShouldPinMe(me: me, page: page, meRowVisible: false), isTrue);
    });
  });

  test('me parses with isMiningNow; rows fall back to sessionStatus', () {
    final response = MiningLeaderboardResponse.fromApi({
      'data': [leaderboardRow(1, status: 'running'), leaderboardRow(2)],
      'total': 2,
      'me': {...leaderboardRow(4, status: 'idle'), 'isMiningNow': true},
    });
    expect(response.me?.rank, 4);
    expect(response.me?.isMiningNow, isTrue);
    expect(response.data.first.isMiningNow, isTrue);
    expect(response.data.last.isMiningNow, isFalse);
    expect(MiningLeaderboardResponse.fromApi({'data': []}).me, isNull);
  });

  testWidgets('9 · page one: header, ten rows, medals for 1–3, pinned me',
      (tester) async {
    final repo = _repo();
    await _pump(tester, repo);

    expect(repo.leaderboardOffsets, [0]);
    expectTopToBottom(tester, [
      find.text('ALL-TIME BNP'),
      find.text('Member 1'),
      find.text('Member 10'),
      find.text('Page 1 of 3'),
      _pinned,
    ]);
    expect(find.text('PAGE 1 OF 3'), findsOneWidget);
    expect(find.text('Member 11'), findsNothing);
    expect(find.text('@member1'), findsOneWidget);
    expect(find.text('mining now'), findsNWidgets(6));
    expect(_rankColor(tester, '1'), AppColors.warning500);
    expect(_rankColor(tester, '2'), AppColors.warning500);
    expect(_rankColor(tester, '3'), AppColors.warning500);
    expect(_rankColor(tester, '4'), AppColors.textMuted);

    expect(
      find.descendant(of: _pinned, matching: find.text('You')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _pinned, matching: find.text('8,412')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _pinned, matching: find.text('mining now')),
      findsOneWidget,
    );
    // Rows open the member's profile.
    final rowTap = tester.widget<InkWell>(
      find.ancestor(of: find.text('Member 2'), matching: find.byType(InkWell)),
    );
    expect(rowTap.onTap, isNotNull);
  });

  testWidgets('paging asks for ten at a time and unpins on my page',
      (tester) async {
    final repo = _repo();
    await _pump(tester, repo);

    await tester.tap(find.byKey(const ValueKey('mine-page-next')));
    await _settle(tester);
    expect(repo.leaderboardOffsets.last, 10);
    expect(find.text('PAGE 2 OF 3'), findsOneWidget);
    expect(find.text('Member 11'), findsOneWidget);
    expect(_pinned, findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mine-page-next')));
    await _settle(tester);
    expect(repo.leaderboardOffsets.last, 20);
    expect(find.text('Member 27'), findsOneWidget);
    expect(_pinned, findsNothing);

    await tester.tap(find.byKey(const ValueKey('mine-page-prev')));
    await _settle(tester);
    expect(repo.leaderboardOffsets.last, 10);
  });

  testWidgets('on my page, the pin shows while my row is scrolled away',
      (tester) async {
    final repo = _repo()
      ..leaderboardMe = {...leaderboardRow(10), 'isMiningNow': false};
    await _pump(tester, repo, height: 360);
    expect(_pinned, findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await _settle(tester);
    expect(_pinned, findsNothing);
  });

  testWidgets('without a me block nothing is pinned', (tester) async {
    await _pump(tester, _repo(withMe: false));
    expect(find.text('Member 1'), findsOneWidget);
    expect(_pinned, findsNothing);
  });
}
