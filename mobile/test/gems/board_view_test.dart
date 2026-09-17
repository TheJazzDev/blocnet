import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/gems/presentation/widgets/board/board_view.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_scroll_view.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gems_fixtures.dart';

void main() {
  late ActionLog log;
  late int discovered;

  setUp(() {
    log = ActionLog();
    discovered = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    GemsLoadState state = GemsLoadState.ready,
    List<GemListing> gems = const [],
  }) async {
    usePhone(tester);
    await tester.pumpWidget(host(BoardView(
      state: state,
      gems: gems,
      now: gemsNow,
      actions: log.actions,
      onDiscover: () => discovered++,
      onRefresh: noRefresh,
    )));
    await tester.pump();
  }

  testWidgets('loading shows a spinner', (tester) async {
    await pump(tester, state: GemsLoadState.loading);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error offers a retry', (tester) async {
    await pump(tester, state: GemsLoadState.error);
    expect(find.text("Couldn't load your board"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('zero follows sends the member to Discover', (tester) async {
    await pump(tester);
    expect(find.text('Your board is empty'), findsOneWidget);
    await tester.tap(find.text('Discover gems'));
    expect(discovered, 1);
  });

  testWidgets('data: newest update per gem, QUIET on the quiet one',
      (tester) async {
    final gems = GemListings.build(
      projects: [
        gemProject('calm', name: 'Calm Gem'),
        gemProject('quiet',
            name: 'Quiet Gem',
            owner: admin('admin-q', username: 'sam'),
            reliability: const OwnerReliability(
              profileId: 'admin-q',
              standing: ReliabilityStanding.quiet,
            )),
      ],
      updates: [
        gemUpdate('u1', 'calm', title: 'Phase 2 live', at: daysAgo(1)),
        gemUpdate('u2', 'quiet', title: 'Old news', at: daysAgo(19)),
      ],
      now: gemsNow,
    );
    await pump(tester, gems: gems);

    expect(find.text('FOLLOWING 2 · 1 QUIET'), findsOneWidget);
    expect(find.text('Phase 2 live'), findsOneWidget);
    expect(find.text(' · 1d ago'), findsOneWidget);
    expect(find.text('Old news'), findsOneWidget);
    expect(find.byKey(const ValueKey('quiet-pill')), findsOneWidget);
    expect(find.text('No update for 19 days'), findsOneWidget);
    // The calm gem comes first: it moved this week.
    final calmY = tester.getTopLeft(find.text('Calm Gem')).dy;
    final quietY = tester.getTopLeft(find.text('Quiet Gem')).dy;
    expect(calmY, lessThan(quietY));

    await tester.tap(find.text('Ask @sam'));
    await tester.tap(find.text('Calm Gem'));
    expect(log.calls, ['ask:quiet', 'open:calm']);
  });

  testWidgets('the row menu unfollows', (tester) async {
    final gems = [listing(gemProject('g1'))];
    await pump(tester, gems: gems);
    await tester.tap(find.byKey(const ValueKey('board-menu-g1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unfollow'));
    await tester.pumpAndSettle();
    expect(log.calls, ['follow:g1']);
  });
}
