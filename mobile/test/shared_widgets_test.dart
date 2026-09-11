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

  group('AppSectionHeader', () {
    testWidgets('uppercases the title and fires the action', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_phone(
        AppSectionHeader(
          title: 'Top Hunters',
          icon: Icons.trending_up_rounded,
          actionLabel: 'View All',
          onAction: () => taps++,
        ),
      ));
      expect(find.text('TOP HUNTERS'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
      await tester.tap(find.text('View All'));
      expect(taps, 1);
    });

    testWidgets('a long title ellipsises rather than overflowing',
        (tester) async {
      await tester.pumpWidget(_phone(
        const AppSectionHeader(
          title: 'A section title far too long to sit on one phone line',
          actionLabel: 'View All',
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('AppEmptyState', () {
    testWidgets('renders icon, title, message and a next step',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_phone(
        AppEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No updates yet',
          message: 'Follow a project and its updates land here.',
          actionLabel: 'Discover projects',
          onAction: () => taps++,
        ),
      ));
      expect(find.text('No updates yet'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      await tester.tap(find.text('Discover projects'));
      expect(taps, 1);
    });

    testWidgets('the error twin tints the icon and defaults to Try again',
        (tester) async {
      await tester.pumpWidget(_phone(
        AppEmptyState.error(title: 'Could not load tips', onAction: () {}),
      ));
      expect(find.text('Try again'), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.error_outline_rounded)).color,
        AppColors.error500,
      );
    });

    testWidgets('no action renders no button', (tester) async {
      await tester.pumpWidget(_phone(
        const AppEmptyState(title: 'Nothing here'),
      ));
      expect(find.byType(AppButton), findsNothing);
    });
  });

  group('AppButton', () {
    testWidgets('primary fills with the accent and presses', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_phone(
        AppButton(label: 'Start Mining', onPressed: () => taps++),
      ));
      await tester.tap(find.text('Start Mining'));
      expect(taps, 1);
      expect(
        tester
            .widget<Material>(find.descendant(
              of: find.byType(AppButton),
              matching: find.byType(Material),
            ))
            .color,
        AppColors.primary500,
      );
    });

    testWidgets('a null onPressed disables it', (tester) async {
      await tester.pumpWidget(_phone(
        const AppButton(label: 'Disabled', onPressed: null),
      ));
      expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.45);
    });

    testWidgets('loading blocks presses but keeps the label', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_phone(
        AppButton(label: 'Saving', onPressed: () => taps++, isLoading: true),
      ));
      expect(find.text('Saving'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Saving'), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('meets the 44px touch target at regular size',
        (tester) async {
      await tester.pumpWidget(_phone(
        AppButton(label: 'Tap', onPressed: () {}),
      ));
      expect(
        tester.getSize(find.byType(AppButton)).height,
        greaterThanOrEqualTo(44),
      );
    });

    testWidgets('danger uses the error tone', (tester) async {
      await tester.pumpWidget(_phone(
        AppButton(
          label: 'Suspend',
          onPressed: () {},
          variant: AppButtonVariant.danger,
        ),
      ));
      expect(
        tester
            .widget<Material>(find.descendant(
              of: find.byType(AppButton),
              matching: find.byType(Material),
            ))
            .color,
        AppColors.error500,
      );
    });
  });

  group('AppStatTile', () {
    testWidgets('renders label, value and a positive delta', (tester) async {
      await tester.pumpWidget(_phone(
        const AppStatTile(
          label: 'Active miners',
          value: '12,480',
          delta: '+8.2% vs. yesterday',
        ),
      ));
      expect(find.text('Active miners'), findsOneWidget);
      expect(find.text('12,480'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('+8.2% vs. yesterday')).style!.color,
        AppColors.successColor,
      );
    });

    testWidgets('a negative delta uses the error tone', (tester) async {
      await tester.pumpWidget(_phone(
        const AppStatTile(
          label: 'Balance',
          value: '120',
          delta: '-4.1%',
          deltaIsPositive: false,
        ),
      ));
      expect(
        tester.widget<Text>(find.text('-4.1%')).style!.color,
        AppColors.error500,
      );
    });

    testWidgets('values use tabular figures so digits do not shuffle',
        (tester) async {
      await tester.pumpWidget(_phone(
        const AppStatTile(label: 'Mined', value: '4,210.55'),
      ));
      final style = tester.widget<Text>(find.text('4,210.55')).style!;
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    testWidgets('fits two across a phone without overflowing', (tester) async {
      await tester.pumpWidget(_phone(
        const Row(
          children: [
            Expanded(child: AppStatTile(label: 'Mining Power', value: '10.0 TH/s')),
            SizedBox(width: AppSpace.md),
            Expanded(child: AppStatTile(label: 'Total Earned', value: '0 BNP')),
          ],
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('AppTextField', () {
    testWidgets('renders label, hint and helper', (tester) async {
      await tester.pumpWidget(_phone(
        const AppTextField(
          label: 'Moderation note',
          hint: 'Why is this being rejected?',
          helper: 'Visible to the project team.',
        ),
      ));
      expect(find.text('Moderation note'), findsOneWidget);
      expect(find.text('Why is this being rejected?'), findsOneWidget);
      expect(find.text('Visible to the project team.'), findsOneWidget);
    });

    testWidgets('an error replaces the helper and tints it', (tester) async {
      await tester.pumpWidget(_phone(
        const AppTextField(
          label: 'Email',
          helper: 'We never share this.',
          errorText: 'That address is already in use.',
        ),
      ));
      expect(find.text('We never share this.'), findsNothing);
      expect(
        tester.widget<Text>(find.text('That address is already in use.'))
            .style!.color,
        AppColors.error500,
      );
    });

    testWidgets('typing reaches onChanged', (tester) async {
      var typed = '';
      await tester.pumpWidget(_phone(
        AppTextField(label: 'Name', onChanged: (v) => typed = v),
      ));
      await tester.enterText(find.byType(TextField), 'Nebula');
      expect(typed, 'Nebula');
    });
  });

  group('AppSheet', () {
    testWidgets('shows a handle, title and content', (tester) async {
      await tester.pumpWidget(_phone(
        const AppSheet(title: 'Switch Space', child: Text('body')),
      ));
      expect(find.text('Switch Space'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('show() opens it over the page and pops on close',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => AppSheet.show<void>(
                context: ctx,
                title: 'Filters',
                builder: (_) => const Text('sheet body'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('sheet body'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('sheet body'), findsNothing);
    });
  });
}
