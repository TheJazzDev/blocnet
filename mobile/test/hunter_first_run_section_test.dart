import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/hunter/presentation/widgets/elite_hunter_banner.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/sections/hunter_first_run_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {List<String>? pushed}) {
  return MaterialApp(
    theme: ThemeData(scaffoldBackgroundColor: AppColors.bgBase),
    onGenerateRoute: (settings) {
      final name = settings.name;
      if (name != null && name != '/') {
        pushed?.add(name);
      }
      return MaterialPageRoute<void>(
        builder: (_) => Scaffold(body: name == '/' ? child : const SizedBox()),
        settings: settings,
      );
    },
  );
}

void main() {
  group('HunterFirstRunSection', () {
    testWidgets('shows one first-run line instead of a wall of zeroes',
        (tester) async {
      await tester.pumpWidget(
        _host(const HunterFirstRunSection(hasManagedProject: true)),
      );

      expect(
        find.text('Your hunter stats start with your first update'),
        findsOneWidget,
      );
      // None of the metric-wall vocabulary should be on screen.
      expect(find.textContaining('Success Rate'), findsNothing);
      expect(find.textContaining('Sentiment'), findsNothing);
      expect(find.textContaining('0%'), findsNothing);
      expect(find.textContaining('N/A'), findsNothing);
    });

    testWidgets('offers posting an update when the hunter manages a gem',
        (tester) async {
      final pushed = <String>[];
      await tester.pumpWidget(
        _host(
          const HunterFirstRunSection(hasManagedProject: true),
          pushed: pushed,
        ),
      );

      expect(find.text('Post an update'), findsOneWidget);
      expect(find.text('Submit a gem'), findsNothing);

      await tester.tap(find.text('Post an update'));
      await tester.pumpAndSettle();

      expect(pushed, [AppRoutes.createUpdate]);
    });

    testWidgets('offers submitting a gem when the hunter has none',
        (tester) async {
      final pushed = <String>[];
      await tester.pumpWidget(
        _host(
          const HunterFirstRunSection(hasManagedProject: false),
          pushed: pushed,
        ),
      );

      expect(find.text('Submit a gem'), findsOneWidget);
      expect(find.text('Post an update'), findsNothing);

      await tester.tap(find.text('Submit a gem'));
      await tester.pumpAndSettle();

      expect(pushed, [AppRoutes.submitProject]);
    });
  });

  group('EliteHunterBanner', () {
    testWidgets('reads as a target, not a failure, before the first update',
        (tester) async {
      await tester.pumpWidget(
        _host(const EliteHunterBanner(qualityRate: 0, hasSignals: false)),
      );

      expect(
        find.text('Elite status starts at a 85% quality rate.'),
        findsOneWidget,
      );
      expect(
        find.text('Post your first update to start tracking your quality rate.'),
        findsOneWidget,
      );
      expect(find.textContaining('Maintain'), findsNothing);
      expect(find.textContaining('Current quality rate: 0%'), findsNothing);
    });

    testWidgets('shows progress towards the target once there are signals',
        (tester) async {
      await tester.pumpWidget(
        _host(const EliteHunterBanner(qualityRate: 40, hasSignals: true)),
      );

      expect(find.text('Your quality rate so far: 40% of 85%'), findsOneWidget);
    });

    testWidgets('confirms the status once the target is met', (tester) async {
      await tester.pumpWidget(
        _host(const EliteHunterBanner(qualityRate: 90, hasSignals: true)),
      );

      expect(find.text('Elite Hunter'), findsOneWidget);
      expect(find.text('Your quality rate: 90%'), findsOneWidget);
    });
  });
}
