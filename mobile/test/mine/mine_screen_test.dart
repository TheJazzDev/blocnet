import 'package:blocnet/features/mining/presentation/pages/mining_screen.dart';
import 'package:blocnet/features/mining/presentation/widgets/help/mine_explainer.dart';
import 'package:blocnet/features/mining/presentation/widgets/help/mine_header_actions.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mine_fixtures.dart';
import '../support/mine_harness.dart';

Future<MiningStore> _pumpScreen(
  WidgetTester tester,
  FakeMineRepo repo, {
  required DateTime now,
  MemoryMineCache? cache,
  double width = 390,
}) async {
  usePhone(tester, width: width);
  final memory = cache ?? MemoryMineCache();
  final store = mineStore(repo, now: now, cache: memory);
  final settings = await loadedSettings(FakeNotificationsRepo());
  await tester.pumpWidget(
    mineHost(
      store: store,
      settings: settings,
      appBar: AppBar(
        title: const Text('Mine'),
        actions: const [MineHeaderActions()],
      ),
      child: MiningScreen(localCache: memory),
    ),
  );
  await _settle(tester);
  return store;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

List<Map<String, dynamic>> _hours(String id, DateTime day, String status,
    {int count = 4}) {
  return [
    for (var i = 0; i < count; i++)
      checkpoint(
        sessionId: id,
        hourStart: day.add(Duration(hours: i)),
        status: status,
      ),
  ];
}

void main() {
  setUp(MineExplainer.instance.reset);

  testWidgets('1 · first visit: sections in order, explainer opens once',
      (tester) async {
    final cache = MemoryMineCache(seenExplainer: false);
    final repo = FakeMineRepo(mineSnapshotJson(balance: 0, lifetime: 0));
    await _pumpScreen(tester, repo, now: runningNow, cache: cache);

    expectTopToBottom(tester, [
      find.text('NOT MINING'),
      find.text('Start mining'),
      find.text('BALANCE'),
      find.text('0'),
      find.text('Converts to BNT at launch.'),
      find.text('View in Wallet'),
      find.text('EARN FASTER'),
      find.text('Invite friends'),
      find.text('+5% per active friend'),
    ]);
    expect(find.text('HOURLY HISTORY'), findsNothing);

    // The popover floats: the card does not move when it closes.
    expectTopToBottom(tester, [
      find.text('How mining works'),
      find.text('Mine BNP in 24-hour cycles.'),
      find.text('Claim within 48 hours, or the cycle expires.'),
      find.text('BNP converts to BNT at launch.'),
      find.text('Got it'),
    ]);
    expect(find.byKey(const ValueKey('mine-help-scrim')), findsOneWidget);
    expect(cache.seenExplainer, isTrue);
    final cardTop = tester.getTopLeft(find.text('NOT MINING'));
    final balanceTop = tester.getTopLeft(find.text('BALANCE'));

    await tester.tap(find.text('Got it'));
    await _settle(tester);
    expect(find.text('How mining works'), findsNothing);
    expect(tester.getTopLeft(find.text('NOT MINING')), cardTop);
    expect(tester.getTopLeft(find.text('BALANCE')), balanceTop);

    // The ? opens it again, still without moving the page.
    await tester.tap(find.byKey(const ValueKey('mine-help')));
    await _settle(tester);
    expect(find.text('How mining works'), findsOneWidget);
    expect(tester.getTopLeft(find.text('NOT MINING')), cardTop);
    await tester.tap(find.byKey(const ValueKey('mine-help-scrim')));
    await _settle(tester);
    expect(find.text('How mining works'), findsNothing);
  });

  testWidgets('the explainer does not open by itself once seen',
      (tester) async {
    final repo = FakeMineRepo(mineSnapshotJson());
    await _pumpScreen(tester, repo, now: runningNow);
    expect(find.text('How mining works'), findsNothing);
  });

  testWidgets('2 · running: inline Earn faster, then leaderboard, then history',
      (tester) async {
    final repo = FakeMineRepo(
      mineSnapshotJson(
        session: runningSession(),
        activeFriends: 2,
        history: [
          ..._hours('run-1', runningStart, 'unclaimed', count: 3),
          ..._hours('old', DateTime(2026, 9, 15, 9), 'claimed'),
        ],
      ),
    )
      ..leaderboardRows = [
        leaderboardRow(1, status: 'running', points: 9000),
        leaderboardRow(2, points: 8000),
        leaderboardRow(3, points: 7000),
      ]
      ..leaderboardTotal = 90
      ..leaderboardMe = leaderboardRow(27, userId: 'me', points: 8412);
    await _pumpScreen(tester, repo, now: runningNow);

    expectTopToBottom(tester, [
      find.text('MINING'),
      find.text("Notify me when it's ready"),
      find.text('BALANCE'),
      find.text('8,412').first,
      find.text('EARN FASTER'),
      find.text('2 active friends · max +100%'),
      find.text('Active means mined in the last 7 days.'),
      find.text('BNC4K92X'),
      find.text('Share code'),
      find.text('LEADERBOARD'),
      find.text('Member 1'),
      find.text('Member 2'),
      find.text('Member 3'),
      find.text('Member 27'),
      find.text('HOURLY HISTORY'),
      find.text('Last 2 days'),
      find.text('1 claimed · 22 BNP'),
    ]);
    expect(find.text('YOU · #27'), findsOneWidget);
    expect(find.text('+10%'), findsNWidgets(2));
    expect(find.text('mining now'), findsOneWidget);
    expect(find.byKey(const ValueKey('mine-earn-row')), findsNothing);
    expect(find.byKey(const ValueKey('mine-primary')), findsNothing);
  });

  testWidgets('5 · claiming shows the receipt above the next running cycle',
      (tester) async {
    final repo = FakeMineRepo(
      mineSnapshotJson(
          asOf: readyNow, session: claimableSession(), activeFriends: 1),
    );
    final store = await _pumpScreen(tester, repo, now: readyNow);
    expect(find.text('Claim 132 BNP'), findsOneWidget);
    expect(find.text('2 active friends · +10%'), findsNothing);

    final next = runningSession(id: 'run-2', startsAt: readyNow, mined: 0);
    repo
      ..claimBody = {
        'ok': true,
        'status': 'claimed',
        'claimedPoints': 126,
        'nextSession': next,
      }
      ..snapshotBody = mineSnapshotJson(
        asOf: readyNow,
        session: next,
        balance: 8538,
        activeFriends: 1,
      );
    await tester.tap(find.text('Claim 132 BNP'));
    await _settle(tester);

    expect(store.lastClaimResult?.isClaimed, isTrue);
    expectTopToBottom(tester, [
      find.text('+126 BNP claimed'),
      find.text('Next cycle started.'),
      find.text('MINING'),
      find.text('Ready tomorrow at 09:20 · 24h left'),
      find.text('8,538'),
    ]);
    expect(find.text('Claim 132 BNP'), findsNothing);
  });

  testWidgets(
      '6 · expired: notice, idle card, history moves up; Dismiss sticks',
      (tester) async {
    final cache = MemoryMineCache();
    final json = mineSnapshotJson(
      activeFriends: 2,
      lastExpiredCycle: {
        'sessionId': 'lost-1',
        'startsAt': iso(DateTime(2026, 9, 14, 9)),
        'endsAt': iso(DateTime(2026, 9, 15, 9)),
        'expiredAt': iso(DateTime(2026, 9, 17, 9)),
        'forfeitedPoints': 132,
      },
      history: [
        ..._hours('won', DateTime(2026, 9, 15, 10), 'claimed'),
        ..._hours('lost-1', DateTime(2026, 9, 14, 16), 'expired'),
      ],
    );
    await _pumpScreen(tester, FakeMineRepo(json),
        now: runningNow, cache: cache);

    expectTopToBottom(tester, [
      find.text('132 BNP expired'),
      find.text("Your 14 Sep cycle wasn't claimed within 48 hours."),
      find.text('Dismiss'),
      find.text('NOT MINING'),
      find.text('Start mining · 132 BNP a day'),
      find.text('Start mining'),
      find.text("Notify me when it's ready"),
      find.text('BALANCE'),
      find.text('HOURLY HISTORY'),
      find.text('1 claimed · 1 expired'),
      find.text('EARN FASTER'),
      find.text('2 active friends · +10%'),
    ]);
    final dismiss = tester.getSize(
      find.ancestor(of: find.text('Dismiss'), matching: find.byType(InkWell)),
    );
    expect(dismiss.height, greaterThanOrEqualTo(44));

    await tester.tap(find.text('Dismiss'));
    await _settle(tester);
    expect(find.text('132 BNP expired'), findsNothing);
    expect(cache.dismissed, contains('lost-1'));

    // A fresh screen remembers the dismissal.
    await tester.pumpWidget(const SizedBox());
    await _pumpScreen(tester, FakeMineRepo(json),
        now: runningNow, cache: cache);
    expect(find.text('132 BNP expired'), findsNothing);
    expect(find.text('NOT MINING'), findsOneWidget);
  });

  testWidgets('7 · paused: no Start, boost applies when mining is back',
      (tester) async {
    final repo = FakeMineRepo(
      mineSnapshotJson(
        enabled: false,
        activeFriends: 2,
        history: [
          ..._hours('a', DateTime(2026, 9, 14, 9), 'claimed', count: 24),
          ..._hours('b', DateTime(2026, 9, 15, 9), 'claimed', count: 24),
        ],
      ),
    );
    await _pumpScreen(tester, repo, now: runningNow);

    expectTopToBottom(tester, [
      find.text('PAUSED BY BLOCNET'),
      find.text('Mining is paused · your balance is safe'),
      find.text('BALANCE'),
      find.text('EARN FASTER'),
      find.text('2 active friends · +10%'),
      find.text('Applies when mining is back'),
      find.text('HOURLY HISTORY'),
      find.text('2 claimed · 264 BNP'),
    ]);
    expect(find.text('Start mining'), findsNothing);
    expect(find.text("Notify me when it's ready"), findsNothing);
  });

  testWidgets('8 · couldn\'t load: no idle card, last balance, Retry works',
      (tester) async {
    final repo = FakeMineRepo(mineSnapshotJson())..failSnapshot = true;
    await _pumpScreen(
      tester,
      repo,
      now: runningNow,
      cache: MemoryMineCache(balance: 8412),
    );

    expectTopToBottom(tester, [
      find.text("Can't reach Blocnet"),
      find.text('Your cycle keeps running. Try again in a moment.'),
      find.text('Retry'),
      find.text('Last balance 8,412 BNP'),
    ]);
    expect(find.text('NOT MINING'), findsNothing);
    expect(find.text('Start mining'), findsNothing);
    expect(find.text('BALANCE'), findsNothing);

    repo.failSnapshot = false;
    await tester.tap(find.text('Retry'));
    await _settle(tester);
    expect(find.text('NOT MINING'), findsOneWidget);
    expect(find.text("Can't reach Blocnet"), findsNothing);
  });

  testWidgets('8 · without a cached balance the line is left out',
      (tester) async {
    final repo = FakeMineRepo(mineSnapshotJson())..failSnapshot = true;
    await _pumpScreen(tester, repo, now: runningNow);
    expect(find.text("Can't reach Blocnet"), findsOneWidget);
    expect(find.textContaining('Last balance'), findsNothing);
  });

  testWidgets('every state lays out at 375 px (iPhone SE)', (tester) async {
    final states = <(DateTime, Map<String, dynamic>)>[
      (runningNow, mineSnapshotJson(balance: 1234567)),
      (
        runningNow,
        mineSnapshotJson(session: runningSession(), activeFriends: 20)
      ),
      (
        readyNow,
        mineSnapshotJson(
            asOf: readyNow, session: claimableSession(points: 2400))
      ),
      (
        soonNow,
        mineSnapshotJson(asOf: soonNow, session: claimableSession(points: 2400))
      ),
      (runningNow, mineSnapshotJson(enabled: false, activeFriends: 2)),
    ];
    for (final (now, json) in states) {
      final repo = FakeMineRepo(json)
        ..leaderboardRows = [
          {
            ...leaderboardRow(1, status: 'running', points: 12345678),
            'displayName': 'A very long display name for a member',
            'username': 'averyveryverylonghandle',
          },
        ]
        ..leaderboardMe = leaderboardRow(1234, userId: 'me', points: 99999);
      await tester.pumpWidget(const SizedBox());
      await _pumpScreen(tester, repo, now: now, width: 375);
      final error = tester.takeException();
      expect(error, isNull, reason: '$now ${json['session']} $error');
    }
  });
}
