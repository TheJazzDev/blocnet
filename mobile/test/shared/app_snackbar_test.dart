import 'package:blocnet/app/theme.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone-sized app whose one button runs [onPressed] with a context
/// inside the app.
Future<void> _pumpHost(
  WidgetTester tester,
  void Function(BuildContext context) onPressed,
) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => onPressed(context),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('info shows the message with the accent info icon',
      (tester) async {
    await _pumpHost(
      tester,
      (context) => AppSnackbar.showInfo(context, 'Nothing to send yet.'),
    );
    await tester.tap(find.text('go'));
    await tester.pump();

    expect(find.text('Nothing to send yet.'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.info_rounded));
    expect(icon.color, AppColors.primary500);
    final ground = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(AppToast),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(ground.color, AppColors.bgElevated);
  });

  test('each kind carries its own colour and icon', () {
    expect(AppToast.styleOf(AppToastKind.success).$1, AppColors.successColor);
    expect(AppToast.styleOf(AppToastKind.error).$1, AppColors.tagWarning);
    expect(AppToast.styleOf(AppToastKind.info).$2, Icons.info_rounded);
  });

  testWidgets('the action runs once and closes the toast', (tester) async {
    var opened = 0;
    await _pumpHost(
      tester,
      (context) => AppSnackbar.showSuccess(
        context,
        'Report sent',
        actionLabel: 'My reports',
        onAction: () => opened++,
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    // pumpAndSettle does not wait out the toast.
    expect(find.text('Report sent'), findsOneWidget);
    await tester.tap(find.text('My reports'));
    await tester.pump();

    expect(opened, 1);
    expect(find.byType(AppToast), findsNothing);
  });

  testWidgets('no action label, no action button', (tester) async {
    await _pumpHost(
      tester,
      (context) => AppSnackbar.showError(context, 'Could not save.'),
    );
    await tester.tap(find.text('go'));
    await tester.pump();

    expect(find.byType(TextButton), findsOneWidget); // only the host's
    expect(find.byIcon(Icons.error_rounded), findsOneWidget);
  });

  testWidgets('it dismisses itself after its duration', (tester) async {
    await _pumpHost(
      tester,
      (context) => AppSnackbar.showInfo(
        context,
        'Press back again to exit',
        duration: const Duration(seconds: 2),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.byType(AppToast), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.byType(AppToast), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(AppToast), findsNothing);
  });

  testWidgets('a new toast replaces the last one', (tester) async {
    var n = 0;
    await _pumpHost(
      tester,
      (context) => AppSnackbar.showInfo(context, 'Toast ${++n}'),
    );
    await tester.tap(find.text('go'));
    await tester.tap(find.text('go'));
    await tester.pump();

    expect(find.byType(AppToast), findsOneWidget);
    expect(find.text('Toast 2'), findsOneWidget);
  });

  testWidgets('a toast shown from an open bottom sheet paints above it',
      (tester) async {
    var taps = 0;
    await _pumpHost(tester, (context) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SizedBox.expand(
          child: ColoredBox(
            color: AppColors.bgSurface,
            child: Center(
              child: TextButton(
                onPressed: () => AppSnackbar.showError(
                  sheetContext,
                  'Could not send.',
                  actionLabel: 'Retry',
                  onAction: () => taps++,
                ),
                child: const Text('send'),
              ),
            ),
          ),
        ),
      );
    });
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('send'));
    await tester.pump();

    // The full-height sheet covers the toast's spot. The toast still takes
    // the tap, so it is painted — and hit-tested — above the sheet.
    final sheetRect = tester.getRect(find.byType(ColoredBox).last);
    final toastRect = tester.getRect(find.byType(AppToast));
    expect(sheetRect.overlaps(toastRect), isTrue);
    final hits = tester.hitTestOnBinding(tester.getCenter(find.text('Retry')));
    final toastBox = tester.renderObject(find.byType(AppToast));
    expect(
      hits.path.any((entry) => identical(entry.target, toastBox)),
      isTrue,
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(taps, 1);
    expect(find.text('send'), findsOneWidget); // the sheet is still open
  });
}
