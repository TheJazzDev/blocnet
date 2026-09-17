import 'dart:async';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/data/models/hunter_gem_detail_model.dart';
import 'package:blocnet/features/hunter/data/models/pending_handover_model.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/gem_page/handover_offer_sheet.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:blocnet/features/profile/data/models/profile_search_result_model.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gem_store_fake.dart';
import 'hub_fixtures.dart';
import 'hub_harness.dart';

HunterGemDetail _withPending(HunterGemDetail base, {int daysAgo = 3}) =>
    HunterGemDetail(
      gem: base.gem,
      updates: base.updates,
      gapDays: base.gapDays,
      pendingHandover: PendingHandover(
        inviteId: 'inv1',
        hunter: const HandoverHunter(id: 'h2', username: 'maya'),
        createdAt: hubNow.subtract(Duration(days: daysAgo)),
      ),
    );

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(byKey('gem-handover'));
  await tester.pumpAndSettle();
}

Text _label(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text));

void main() {
  for (final width in hubWidths) {
    group('@${width.toInt()}', () {
      testWidgets('Post update and Hand over share the row equally',
          (tester) async {
        await pumpGemPage(tester, haloDetail(), width: width);
        expect(tester.takeException(), isNull);

        final post = tester.getRect(byKey('gem-post'));
        final hand = tester.getRect(byKey('gem-handover'));
        expect(post.height, 40);
        expect(hand.height, 40);
        expect(post.width, closeTo(hand.width, 0.5));
        expect(post.top, hand.top);
        expect(hand.left - post.right, 8);
        expect(hand.right, lessThanOrEqualTo(width - 16));

        final button = tester.widget<AppButton>(byKey('gem-handover')).variant;
        expect(button, AppButtonVariant.tinted);
        expect(_label(tester, 'Hand over').style?.color, AppColors.tagAirdrop);
        expect(_label(tester, 'Post update').style?.color, Colors.black);
      });

      testWidgets('a never-updated gem still fits both buttons',
          (tester) async {
        await pumpGemPage(
          tester,
          HunterGemDetail(
            gem: gem('Prism', neverUpdated: true, lastTitle: null),
            updates: const [],
          ),
          width: width,
        );
        expect(tester.takeException(), isNull);
        // The short label: "Post the first update" cannot fit half a row.
        expect(inside(byKey('gem-post'), find.text('First update')),
            findsOneWidget);
        expect(inside(byKey('gem-handover'), find.text('Hand over')),
            findsOneWidget);
        expect(tester.getRect(byKey('gem-handover')).right,
            lessThanOrEqualTo(width - 16));
      });

      testWidgets('the sheet needs a hunter before it can offer',
          (tester) async {
        final store = await pumpGemPage(tester, haloDetail(), width: width);
        await _openSheet(tester);
        expect(tester.takeException(), isNull);

        expect(find.text('Hand over Halo Points'), findsOneWidget);
        expect(find.text(HandoverOfferSheet.explainer), findsOneWidget);
        expect(
          tester.widget<AppButton>(byKey('handover-offer')).onPressed,
          isNull,
        );

        await tester.enterText(byKey('handover-hunter'), '  @ ');
        await tester.pump();
        expect(
          tester.widget<AppButton>(byKey('handover-offer')).onPressed,
          isNull,
          reason: 'a bare @ is not a hunter',
        );
        await tester.tap(byKey('handover-offer'));
        await tester.pump();
        expect(store.offers, isEmpty);

        await tester.enterText(byKey('handover-note'), 'x' * 300);
        await tester.pump();
        final note = tester.widget<TextField>(byKey('handover-note'));
        expect(note.controller!.text.length, HandoverOfferSheet.maxNoteLength);
      });

      testWidgets('offering calls the store, closes, and says so',
          (tester) async {
        final store = await pumpGemPage(tester, haloDetail(), width: width);
        await _openSheet(tester);

        await tester.enterText(byKey('handover-hunter'), '@maya');
        await tester.enterText(byKey('handover-note'), 'Back in October');
        await tester.pump();

        store.gate = Completer<void>();
        await tester.tap(byKey('handover-offer'));
        await tester.pump();
        expect(tester.widget<AppButton>(byKey('handover-offer')).isLoading,
            isTrue);

        store.gate!.complete();
        await tester.pumpAndSettle();

        expect(store.offers, [('p-halo-points', '@maya', 'Back in October')]);
        expect(byKey('handover-offer-sheet'), findsNothing);
        expect(
          find.text('Handover offered to @maya. You stay responsible until '
              'they accept.'),
          findsOneWidget,
        );
        expect(store.loads, 2, reason: 'the gem reloads after the offer');
        expect(store.boardLoads, 1);
      });

      testWidgets('a refusal stays in the sheet', (tester) async {
        final store = await pumpGemPage(tester, haloDetail(), width: width);
        await _openSheet(tester);
        store.failWith = 'That hunter already has a handover pending.';

        await tester.enterText(byKey('handover-hunter'), '@maya');
        await tester.pump();
        await tester.tap(byKey('handover-offer'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(byKey('handover-offer-sheet'), findsOneWidget);
        expect(
          inside(byKey('handover-error'),
              find.text('That hunter already has a handover pending.')),
          findsOneWidget,
        );
        expect(find.byType(AppToast), findsNothing);
        expect(store.loads, 1);
      });

      testWidgets('a suggestion fills the hunter field', (tester) async {
        await pumpGemPage(
          tester,
          haloDetail(),
          width: width,
          search: (_) async => const [
            ProfileSearchResult(
              id: 'h2',
              displayName: 'Maya Chen',
              username: 'maya',
              avatarUrl: null,
              followersCount: 0,
              roles: ['hunter'],
            ),
          ],
        );
        await _openSheet(tester);
        await tester.enterText(byKey('handover-hunter'), 'ma');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();
        await tester.tap(find.text('Maya Chen'));
        await tester.pump();
        final field = tester.widget<TextField>(byKey('handover-hunter'));
        expect(field.controller!.text, '@maya');
        expect(
          tester.widget<AppButton>(byKey('handover-offer')).onPressed,
          isNotNull,
        );
      });

      testWidgets('a pending handover can be withdrawn', (tester) async {
        final store = await pumpGemPage(
          tester,
          _withPending(haloDetail()),
          width: width,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Hand over'), findsNothing);
        expect(inside(byKey('gem-handover'), find.text('Handover pending')),
            findsOneWidget);

        await _openSheet(tester);
        expect(
          find.text('Waiting for @maya to answer · offered 3 days ago'),
          findsOneWidget,
        );
        expect(
          tester.widget<AppButton>(byKey('handover-withdraw')).variant,
          AppButtonVariant.tinted,
        );

        await tester.tap(byKey('handover-withdraw'));
        await tester.pumpAndSettle();
        expect(store.cancels, ['p-halo-points']);
        expect(byKey('handover-pending-sheet'), findsNothing);
        expect(store.loads, 2);
        expect(store.offers, isEmpty);
      });
    });
  }

  testWidgets('a handover offered today says so, and a failed withdraw stays',
      (tester) async {
    final store = await pumpGemPage(
      tester,
      _withPending(haloDetail(), daysAgo: 0),
    );
    await _openSheet(tester);
    expect(find.text('Waiting for @maya to answer · offered today'),
        findsOneWidget);

    store.failWith = 'Could not withdraw the handover. Please try again.';
    await tester.tap(byKey('handover-withdraw'));
    await tester.pumpAndSettle();
    expect(byKey('handover-pending-sheet'), findsOneWidget);
    expect(find.text('Could not withdraw the handover. Please try again.'),
        findsOneWidget);
    expect(store.loads, 1);
  });
}
