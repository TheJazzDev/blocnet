import 'package:blocnet/features/hunter/presentation/widgets/become_hunter/become_hunter_form.dart';
import 'package:blocnet/features/hunter/presentation/widgets/become_hunter/become_hunter_hero.dart';
import 'package:blocnet/features/hunter/presentation/widgets/become_hunter/become_hunter_status_card.dart';
import 'package:blocnet/services/users/hunter_application_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _IdleStore extends HunterApplicationStore {
  _IdleStore({this.submitting = false});

  final bool submitting;
  int submits = 0;

  @override
  bool get isSubmitting => submitting;

  @override
  Future<bool> submit(String reason) async {
    submits += 1;
    return true;
  }
}

Future<void> _pump(
  WidgetTester tester,
  HunterApplicationStore store,
  List<Widget> children,
) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<HunterApplicationStore>.value(
      value: store,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(children: children),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the intro and form fit a 375px phone without gradients',
      (tester) async {
    await _pump(tester, _IdleStore(), const [
      BecomeHunterHero(),
      BecomeHunterForm(),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('HUNTERS'), findsOneWidget);
    expect(find.text('WHAT WE LOOK FOR'), findsOneWidget);
    expect(find.byType(AppPill), findsNWidgets(3));

    final gradients = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.gradient != null);
    expect(gradients, isEmpty);
  });

  testWidgets('a short reason is refused before it reaches the store',
      (tester) async {
    final store = _IdleStore();
    await _pump(tester, store, const [BecomeHunterForm()]);

    await tester.enterText(find.byType(TextField), 'too short');
    await tester.tap(find.text('Apply to become a Hunter'));
    await tester.pump();

    expect(store.submits, 0);
    expect(find.textContaining('at least 20 characters'), findsOneWidget);
  });

  testWidgets('the apply button is disabled while sending', (tester) async {
    await _pump(tester, _IdleStore(submitting: true), const [
      BecomeHunterForm(),
    ]);

    final button = tester.widget<AppButton>(find.byType(AppButton));
    expect(button.onPressed, isNull);
    expect(button.isLoading, isTrue);
  });

  testWidgets('status cards carry a pill and only the hunter card acts',
      (tester) async {
    var opened = 0;
    await _pump(tester, _IdleStore(), [
      const BecomeHunterStatusCard.pending(),
      const BecomeHunterStatusCard.rejected(),
      BecomeHunterStatusCard.alreadyHunter(onOpenHunterSpace: () => opened++),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('IN REVIEW'), findsOneWidget);
    expect(find.text('NOT APPROVED'), findsOneWidget);
    expect(find.byType(AppButton), findsOneWidget);

    await tester.tap(find.text('Open Hunter space'));
    expect(opened, 1);

    // Coloured tone lives in the pill, not the card border.
    final surfaces = tester.widgetList<AppSurface>(find.byType(AppSurface));
    expect(surfaces.every((s) => s.borderColor == null), isTrue);
  });
}
