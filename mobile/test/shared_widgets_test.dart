import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps in a phone-width scaffold. Any RenderFlex overflow inside becomes a
/// test failure, which is what caught the two layouts the scale broke.
Widget _phone(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.bgBase,
        body: SizedBox(width: 375, child: child),
      ),
    );

void main() {
  group('AppSurface', () {
    testWidgets('renders its child and paints the tone background',
        (tester) async {
      await tester.pumpWidget(_phone(
        const AppSurface(child: Text('Nebula Swap')),
      ));
      expect(find.text('Nebula Swap'), findsOneWidget);

      final box = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppSurface),
          matching: find.byType(Container),
        ),
      );
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.bgSurface);
      expect(decoration.borderRadius, AppRadius.md);
      expect(decoration.border, isNotNull);
    });

    testWidgets('elevated tone and borderless variant', (tester) async {
      await tester.pumpWidget(_phone(
        const AppSurface(
          tone: AppSurfaceTone.elevated,
          bordered: false,
          child: Text('x'),
        ),
      ));
      final decoration = tester
          .widget<Container>(
            find.descendant(
              of: find.byType(AppSurface),
              matching: find.byType(Container),
            ),
          )
          .decoration! as BoxDecoration;
      expect(decoration.color, AppColors.bgElevated);
      expect(decoration.border, isNull);
    });

    testWidgets('onTap makes it tappable and clips the splash to the radius',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_phone(
        AppSurface(onTap: () => taps++, child: const Text('tap me')),
      ));
      await tester.tap(find.text('tap me'));
      expect(taps, 1);
      expect(
        tester.widget<InkWell>(find.byType(InkWell)).borderRadius,
        AppRadius.md,
      );
    });

    testWidgets('a gradient replaces the tone fill', (tester) async {
      const gradient = LinearGradient(colors: [Colors.red, Colors.blue]);
      await tester.pumpWidget(_phone(
        const AppSurface(gradient: gradient, child: Text('x')),
      ));
      final decoration = tester
          .widget<Container>(
            find.descendant(
              of: find.byType(AppSurface),
              matching: find.byType(Container),
            ),
          )
          .decoration! as BoxDecoration;
      expect(decoration.gradient, gradient);
      expect(decoration.color, isNull);
    });
  });

  group('AppPill', () {
    testWidgets('tinted is the default and tints from the given colour',
        (tester) async {
      await tester.pumpWidget(_phone(
        const AppPill(label: 'Pending', color: Color(0xFF22D3EE)),
      ));
      expect(find.text('Pending'), findsOneWidget);
      final decoration = tester
          .widget<Container>(
            find.descendant(
              of: find.byType(AppPill),
              matching: find.byType(Container),
            ),
          )
          .decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFF22D3EE).withValues(alpha: 0.12));
      expect(decoration.borderRadius, AppRadius.full);
    });

    testWidgets('filled inverts to dark text on the tone', (tester) async {
      await tester.pumpWidget(_phone(
        const AppPill(
          label: 'Featured',
          color: Color(0xFF22D3EE),
          style: AppPillStyle.filled,
        ),
      ));
      final decoration = tester
          .widget<Container>(
            find.descendant(
              of: find.byType(AppPill),
              matching: find.byType(Container),
            ),
          )
          .decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFF22D3EE));
      expect(
        tester.widget<Text>(find.text('Featured')).style!.color,
        AppColors.bgBase,
      );
    });

    testWidgets('uppercase and icon variants render', (tester) async {
      await tester.pumpWidget(_phone(
        const AppPill(
          label: 'current',
          icon: Icons.check_rounded,
          uppercase: true,
          dense: true,
        ),
      ));
      expect(find.text('CURRENT'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('dense fits a narrow grid tile without overflowing',
        (tester) async {
      await tester.pumpWidget(_phone(
        const Center(
          child: SizedBox(
            width: 96,
            child: Center(
              child: AppPill(label: 'CURRENT', dense: true),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('AppListRow', () {
    testWidgets('renders title, subtitle, leading and trailing',
        (tester) async {
      await tester.pumpWidget(_phone(
        const AppListRow(
          leading: Icon(Icons.person),
          title: 'Ada Lovelace',
          subtitle: '@ada',
          trailing: Text('4,210'),
        ),
      ));
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('@ada'), findsOneWidget);
      expect(find.text('4,210'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('title uses body size, and label size when dense',
        (tester) async {
      await tester.pumpWidget(_phone(const AppListRow(title: 'Wallet')));
      expect(
        tester.widget<Text>(find.text('Wallet')).style!.fontSize,
        AppText.bodySize,
      );

      await tester.pumpWidget(_phone(
        const AppListRow(title: 'Wallet', dense: true),
      ));
      expect(
        tester.widget<Text>(find.text('Wallet')).style!.fontSize,
        AppText.labelSize,
      );
    });

    testWidgets('a long title ellipsises instead of overflowing',
        (tester) async {
      await tester.pumpWidget(_phone(
        const AppListRow(
          leading: Icon(Icons.folder),
          title: 'An extremely long project name that cannot possibly fit '
              'inside a single row on a phone screen',
          subtitle: 'and a subtitle that is also far too long to fit here',
          trailing: Text('999'),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Text>(find.textContaining('extremely long')).overflow,
        TextOverflow.ellipsis,
      );
    });

    testWidgets('onTap fires', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_phone(
        AppListRow(title: 'Settings', onTap: () => taps++),
      ));
      await tester.tap(find.text('Settings'));
      expect(taps, 1);
    });
  });
}
