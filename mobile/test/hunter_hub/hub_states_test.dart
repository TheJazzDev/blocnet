import 'package:blocnet/features/hunter/domain/coverage_sentence.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_deadline_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hub_fixtures.dart';
import 'hub_harness.dart';

/// Hunter Hub states 1–5, walked against the element lists in
/// `docs/design-briefs/hunter-hub-build-spec.md`, at 375 and 390 wide.
void main() {
  for (final width in hubWidths) {
    group('@${width.toInt()}', () {
      testWidgets('state 1 · all current', (tester) async {
        await pumpHub(tester, allCurrentBoard(), width: width);
        expect(tester.takeException(), isNull);

        final board = allCurrentBoard();
        expectVerticalOrder(tester, [
          byKey('hub-identity'),
          byKey('hub-reliability'),
          byKey('hub-reach'),
          byKey('hub-section-gems'),
          for (final g in board.gems) rowOf(g.projectId),
        ]);

        // Identity row.
        expect(find.text('Jazzdev'), findsOneWidget);
        expect(find.text('15'), findsOneWidget);
        expect(find.text('HUNTER'), findsOneWidget);
        expect(find.text('@jazzdev · Ruby · Pioneer'), findsOneWidget);

        // Reliability card.
        expect(find.text('RELIABLE'), findsOneWidget);
        expect(find.text('LAST 14 DAYS'), findsOneWidget);
        expect(find.text('5 of 5'), findsOneWidget);
        expect(find.text('gems current'), findsOneWidget);
        expect(
          find.text('Every gem you own has an update from the last 14 days.'),
          findsOneWidget,
        );
        expect(byKey('hub-pip-current'), findsNWidgets(5));
        expect(byKey('hub-pip-attention'), findsNothing);
        expect(find.text('4 of 4'), findsOneWidget);
        expect(find.text('5 days'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(find.text('RESPONSE'), findsOneWidget);
        expect(find.text('CADENCE'), findsOneWidget);
        expect(find.text('WAITING'), findsOneWidget);

        // Reach row.
        expect(find.text('18,240 BNP'), findsOneWidget);
        expect(find.text('26,465'), findsOneWidget);
        expect(find.text('TIPS'), findsOneWidget);
        expect(find.text('FOLLOWERS'), findsOneWidget);

        // Section and condensed rows.
        expect(find.text('YOUR GEMS'), findsOneWidget);
        expect(find.text('5 CURRENT'), findsOneWidget);
        final core = rowOf('p-core-mines');
        expect(inside(core, find.text('Core Mines')), findsOneWidget);
        expect(inside(core, find.text('CORE')), findsOneWidget);
        expect(inside(core, find.text('8,412 · 3h ago')), findsOneWidget);
        expect(inside(core, find.byIcon(Icons.check_circle_rounded)),
            findsOneWidget);
        expect(inside(rowOf('p-bless50ing'), find.text('B5')), findsOneWidget);
        expect(inside(rowOf('p-bless50ing'), find.text('TELEGRAM')),
            findsOneWidget);
        expect(
            inside(rowOf('p-solar-relay'), find.text('BSC')), findsOneWidget);

        // Nothing else.
        expect(find.text('Post update'), findsNothing);
        expect(byKey('hub-fold'), findsNothing);
        expect(byKey('hub-section-current'), findsNothing);
        expect(find.text('NEEDS YOUR ANSWER'), findsNothing);
      });

      testWidgets('state 2 · one gem slipping', (tester) async {
        final calls = await pumpHub(tester, slippingBoard(), width: width);
        expect(tester.takeException(), isNull);

        expectVerticalOrder(tester, [
          byKey('hub-identity'),
          byKey('hub-reliability'),
          byKey('hub-section-gems'),
          rowOf('p-halo-points'),
          rowOf('p-terra-vault'),
          byKey('hub-section-current'),
          rowOf('p-core-mines'),
          rowOf('p-bless50ing'),
          rowOf('p-nebula-swap'),
        ]);
        expect(byKey('hub-reach'), findsNothing, reason: 'D6');

        expect(find.text('SLIPPING'), findsOneWidget);
        expect(find.text('3 of 5'), findsOneWidget);
        expect(
          find.text('Halo Points is quiet at 19 days. Terra Vault is due.'),
          findsOneWidget,
        );
        expect(byKey('hub-pip-current'), findsNWidgets(3));
        expect(byKey('hub-pip-attention'), findsNWidgets(2));
        expect(find.text('2 of 5'), findsOneWidget);
        expect(find.text('9 days'), findsOneWidget);
        expect(find.text('38'), findsOneWidget);
        expect(find.text('2 NEED YOU'), findsOneWidget);

        final halo = rowOf('p-halo-points');
        expect(inside(halo, find.text('ETHEREUM')), findsOneWidget);
        expect(inside(halo, find.text('4,730 following')), findsOneWidget);
        expect(inside(halo, find.text('QUIET')), findsOneWidget);
        expect(
          inside(halo,
              richText('Farming round 2 is live · last update 19 days ago')),
          findsOneWidget,
        );
        expect(inside(halo, find.text('31 members waiting')), findsOneWidget);
        expect(inside(halo, find.text('2 reports')), findsOneWidget);
        expect(inside(halo, find.text('Post update')), findsOneWidget);
        expect(inside(halo, find.text('Open gem')), findsOneWidget);
        expectVerticalOrder(tester, [
          inside(halo, find.text('Halo Points')),
          inside(
              halo,
              richText('Farming round 2 is live · '
                  'last update 19 days ago')),
          inside(halo, find.text('31 members waiting')),
          inside(halo, find.text('Post update')),
        ]);

        final terra = rowOf('p-terra-vault');
        final deadline = describeDeadline(fridayEvening, hubNow).label;
        expect(inside(terra, find.text('DUE')), findsOneWidget);
        expect(inside(terra, find.text('ICE')), findsOneWidget);
        expectVerticalOrder(tester, [
          inside(terra, find.text('Terra Vault')),
          inside(terra,
              richText('Vault caps raised to 5M · last update 11 days ago')),
          inside(terra, find.text(deadline)),
          inside(terra, find.text('7 members waiting')),
        ]);
        expect(inside(terra, byKey('gem-reports')), findsNothing,
            reason: 'reports hidden at zero');
        // D2: due rows carry no buttons.
        expect(inside(terra, find.text('Post update')), findsNothing);
        expect(inside(terra, find.text('Open gem')), findsNothing);

        expect(find.text('CURRENT'), findsOneWidget);
        expect(find.text('3 GEMS'), findsOneWidget);
        expect(byKey('hub-fold'), findsNothing, reason: 'D3: three or fewer');

        await tester.tap(inside(halo, find.text('Post update')));
        await tester.tap(inside(halo, find.text('Open gem')));
        await tester.tap(inside(terra, find.text('Terra Vault')));
        expect(calls.posted, ['Halo Points']);
        expect(calls.opened, ['Halo Points', 'Terra Vault']);
      });

      testWidgets('state 3 · day one', (tester) async {
        final calls = await pumpHub(tester, dayOneBoard(), width: width);
        expect(tester.takeException(), isNull);

        expectVerticalOrder(tester, [
          byKey('hub-identity'),
          byKey('hub-day-one'),
          byKey('hub-section-standing'),
          byKey('hub-reliability'),
          byKey('hub-section-measured'),
          byKey('hub-measured'),
        ]);
        expect(find.text('@mikko · Iron · Explorer'), findsOneWidget);
        expect(inside(byKey('hub-identity'), find.text('2')), findsOneWidget,
            reason: 'Iron badge');
        expect(find.text("You're a hunter now"), findsOneWidget);
        expect(find.textContaining('A gem is a project you found'),
            findsOneWidget);
        expectVerticalOrder(tester, [
          find.text('Submit your first gem'),
          find.text('Or accept an invite'),
        ]);
        expect(find.text('Diligence, then a first update'), findsOneWidget);

        // No invites: step 2 says so, and nothing about it is tappable.
        final invite = byKey('day-one-invite');
        expect(inside(invite, find.text('No invites yet')), findsOneWidget);
        expect(inside(invite, find.byIcon(Icons.chevron_right_rounded)),
            findsNothing);
        expect(inside(invite, find.byType(GestureDetector)), findsNothing);

        expect(find.text('STANDING'), findsOneWidget);
        expect(find.text('NEW'), findsOneWidget);
        expect(find.text('NO GEMS YET'), findsOneWidget);
        expect(find.text(dayOneStandingSentence), findsOneWidget);
        expect(find.text('gems current'), findsNothing);
        expect(byKey('hub-pips'), findsNothing);
        expect(find.text('RESPONSE'), findsNothing);
        expect(find.text('HOW RELIABILITY IS MEASURED'), findsOneWidget);
        expect(find.textContaining('Coverage — gems updated'), findsOneWidget);
        expect(byKey('hub-reach'), findsNothing);
        expect(byKey('hub-section-gems'), findsNothing);

        await tester.tap(find.text('Submit your first gem'));
        expect(calls.submits, 1);
      });

      testWidgets('state 3 · day one with an invite scrolls to it',
          (tester) async {
        await pumpHub(tester, dayOneBoard(),
            width: width, invites: [nebulaInvite()]);
        expect(tester.takeException(), isNull);
        final invite = byKey('day-one-invite');
        expect(inside(invite, find.text('Co-own a gem already running')),
            findsOneWidget);
        expect(inside(invite, find.byIcon(Icons.chevron_right_rounded)),
            findsOneWidget);
        expectVerticalOrder(tester, [
          byKey('hub-day-one'),
          byKey('hub-invite-inv-1'),
          byKey('hub-section-standing'),
        ]);
        // Push the page down so the invite is off screen, then tap.
        usePhone(tester, width, height: 700);
        await tester.pumpAndSettle();
        final before = tester.getTopLeft(byKey('hub-invite-inv-1')).dy;
        await tester.tap(find.text('Or accept an invite'));
        await tester.pumpAndSettle();
        expect(
            tester.getTopLeft(byKey('hub-invite-inv-1')).dy, lessThan(before));
      });

      testWidgets('state 4 · invites and reviews', (tester) async {
        final calls = await pumpHub(
          tester,
          invitesBoard(),
          width: width,
          invites: [nebulaInvite()],
          proposals: [lumenPay()],
        );
        expect(tester.takeException(), isNull);

        expectVerticalOrder(tester, [
          byKey('hub-identity'),
          byKey('hub-reliability'),
          find.text('NEEDS YOUR ANSWER'),
          byKey('hub-invite-inv-1'),
          byKey('hub-review-pp-1'),
          byKey('hub-section-gems'),
          rowOf('p-orbit-lend'),
          rowOf('p-ice-drift'),
        ]);
        expect(byKey('hub-reach'), findsNothing, reason: 'D6');
        expect(find.text('@ada · Amethyst · Elite'), findsOneWidget);
        expect(find.text('2 of 2'), findsOneWidget);
        expect(
          find.text('Both gems have an update from the last 14 days.'),
          findsOneWidget,
        );
        expect(byKey('hub-pip-current'), findsNWidgets(2));
        expect(find.text('3 of 3'), findsOneWidget);
        expect(find.text('4 days'), findsOneWidget);

        final invite = byKey('hub-invite-inv-1');
        expect(inside(invite, find.text('Nebula Swap')), findsOneWidget);
        expect(inside(invite, find.text('NS')), findsOneWidget);
        expect(inside(invite, find.text('INVITE')), findsOneWidget);
        expect(
          inside(
            invite,
            richText('@abtoonzz is handing over coverage. 12,740 followers, '
                '34 updates posted, last one 2 days ago. Accept and the '
                'obligation is yours.'),
          ),
          findsOneWidget,
        );
        final accept = tester.getSize(inside(invite, find.text('Accept')));
        expect(accept.height, greaterThan(0));
        final acceptBox = tester.getRect(find
            .ancestor(of: find.text('Accept'), matching: find.byType(Expanded))
            .first);
        final declineBox = tester.getRect(find
            .ancestor(of: find.text('Decline'), matching: find.byType(Expanded))
            .first);
        expect(acceptBox.width, closeTo(declineBox.width, 0.5));

        final review = byKey('hub-review-pp-1');
        expect(inside(review, find.text('Lumen Pay')), findsOneWidget);
        expect(inside(review, find.text('IN REVIEW')), findsOneWidget);
        expect(
          inside(
            review,
            find.text('Submitted 2 days ago. A moderator is checking the '
                "diligence. You'll get a notification either way."),
          ),
          findsOneWidget,
        );
        expect(find.text('2 CURRENT'), findsOneWidget);
        expect(inside(rowOf('p-orbit-lend'), find.text('1,884 · 5h ago')),
            findsOneWidget);

        await tester.tap(find.text('Accept'));
        await tester.tap(find.text('Decline'));
        expect(calls.responses, ['inv-1:true', 'inv-1:false']);
      });

      testWidgets('state 5 · a dozen gems', (tester) async {
        await pumpHub(tester, dozenBoard(), width: width);
        expect(tester.takeException(), isNull);

        expectVerticalOrder(tester, [
          byKey('hub-identity'),
          byKey('hub-reliability'),
          byKey('hub-section-gems'),
          rowOf('p-aegis-node'),
          rowOf('p-halo-points'),
          rowOf('p-terra-vault'),
          byKey('hub-fold'),
        ]);
        expect(byKey('hub-reach'), findsNothing);
        expect(find.text('9 of 12'), findsOneWidget);
        expect(
          find.text('Two quiet, one due. Aegis Node is the oldest at 21 days.'),
          findsOneWidget,
        );
        expect(byKey('hub-pip-current'), findsNWidgets(9));
        expect(byKey('hub-pip-attention'), findsNWidgets(3));
        expect(find.text('6 of 9'), findsOneWidget);
        expect(find.text('7 days'), findsOneWidget);
        expect(find.text('52'), findsOneWidget);
        expect(find.text('3 NEED YOU'), findsOneWidget);

        // D3: compact copy.
        final aegis = rowOf('p-aegis-node');
        expect(
            inside(aegis, richText('Node sale allocations sent · 21 days ago')),
            findsOneWidget);
        expect(inside(aegis, find.text('28 waiting')), findsOneWidget);
        expect(inside(aegis, find.text('3 reports')), findsOneWidget);
        expect(inside(aegis, find.text('Post update')), findsOneWidget);
        final halo = rowOf('p-halo-points');
        expect(inside(halo, find.text('19 waiting')), findsOneWidget);
        expect(inside(halo, byKey('gem-reports')), findsNothing);
        expect(inside(halo, find.text('Open gem')), findsOneWidget);
        final terra = rowOf('p-terra-vault');
        expect(inside(terra, find.text('5 waiting')), findsOneWidget);
        expect(
            inside(terra,
                find.text(describeDeadline(fridayEvening, hubNow).label)),
            findsOneWidget);
        expect(inside(terra, find.text('Post update')), findsNothing);
        expect(find.textContaining('last update'), findsNothing);
        expect(find.textContaining('members waiting'), findsNothing);

        // The fold.
        expect(find.text('9 current, all posted this week'), findsOneWidget);
        expect(byKey('hub-section-current'), findsNothing);
        expect(rowOf('p-current-0'), findsNothing);
        await tester.ensureVisible(byKey('hub-fold'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('hub-fold'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expectVerticalOrder(tester, [
          byKey('hub-fold'),
          for (var i = 0; i < 9; i++) rowOf('p-current-$i'),
        ]);
      });

      testWidgets('a never-updated gem offers only its first update',
          (tester) async {
        final board = slippingBoard();
        final calls = await pumpHub(
          tester,
          board.copyWithGems([prismYield(), ...board.gems.skip(2)]),
          width: width,
        );
        expect(tester.takeException(), isNull);
        final prism = rowOf('p-prism-yield');
        expect(inside(prism, find.text('DUE')), findsOneWidget);
        expect(inside(prism, find.text('No updates yet · listed 12 days ago')),
            findsOneWidget);
        expect(
            inside(prism, find.text('Post the first update')), findsOneWidget);
        expect(inside(prism, find.text('Open gem')), findsNothing);
        await tester.tap(find.text('Post the first update'));
        expect(calls.posted, ['Prism Yield']);
      });

      testWidgets(
          'an unscored hunter with gems sees the board under a new card',
          (tester) async {
        await pumpHub(tester, newWithGemsBoard(), width: width);
        expect(tester.takeException(), isNull);
        expect(find.text('NEW'), findsOneWidget);
        expect(find.text(unscoredSentence), findsOneWidget);
        expect(find.text('gems current'), findsNothing);
        expectVerticalOrder(tester, [
          byKey('hub-reliability'),
          byKey('hub-section-gems'),
          rowOf('p-core-mines'),
        ]);
      });
    });
  }
}
