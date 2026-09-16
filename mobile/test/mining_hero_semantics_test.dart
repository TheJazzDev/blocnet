import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/widgets/mining_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mining_fixtures.dart';

MiningSnapshot _snapshot({Map<String, dynamic>? session}) {
  return MiningSnapshot.fromApi(
    miningSnapshotJson(session: session, cycleHours: 12),
  );
}

void main() {
  DateTime now = miningAsOf;

  Widget host(MiningSnapshot snapshot) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MiningHeroCard(
            snapshot: snapshot,
            onStart: () {},
            onClaim: () {},
            isStarting: false,
            isClaiming: false,
            isLoadingSnapshot: false,
            serverNow: () => now,
          ),
        ),
      ),
    );
  }

  setUp(() => now = miningAsOf);

  testWidgets('hero label follows the state, not a stale idle label',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(host(_snapshot()));
    expect(
      find.bySemanticsLabel(
        RegExp(
          r'^Not mining\. Start to begin your \d+ hour cycle, '
          r'earning 5 BNP per hour$',
        ),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Start Mining'), findsOneWidget);
    // The pieces are not read on their own.
    expect(find.bySemanticsLabel('IDLE'), findsNothing);

    await tester.pumpWidget(host(_snapshot(session: runningSessionJson())));
    final running = RegExp(
      r'^Mining, ready at .+ (today|tomorrow), 60 BNP so far$',
    );
    expect(find.bySemanticsLabel(running), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Not mining')), findsNothing);
    expect(find.bySemanticsLabel('Start Mining'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('LIVE|IDLE')), findsNothing);

    // The button reads what it shows, and keeps up with the clock.
    expect(find.bySemanticsLabel('Claim in 01:00:00'), findsOneWidget);
    now = miningAsOf.add(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel('Claim in 59:55'), findsOneWidget);
    // The summary names a fixed time, so it does not churn every second.
    expect(find.bySemanticsLabel(running), findsOneWidget);

    await tester.pumpWidget(
      host(_snapshot(session: runningSessionJson(status: 'claimable'))),
    );
    expect(
      find.bySemanticsLabel('Mining cycle complete, 60 BNP ready to claim'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Claim Rewards'), findsOneWidget);
    expect(find.bySemanticsLabel(running), findsNothing);

    semantics.dispose();
  });

  testWidgets('hero summary is a single node', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(_snapshot(session: runningSessionJson())));

    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'^Mining, ready at')),
    );
    expect(node.label, contains('60 BNP so far'));
    expect(node.label, isNot(contains('%')));

    semantics.dispose();
  });
}
