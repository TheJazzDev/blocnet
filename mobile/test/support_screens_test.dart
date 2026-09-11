import 'package:blocnet/features/support/data/faq_content.dart';
import 'package:blocnet/features/support/data/getting_started_content.dart';
import 'package:blocnet/features/support/presentation/pages/faq_screen.dart';
import 'package:blocnet/features/support/presentation/pages/getting_started_screen.dart';
import 'package:blocnet/features/support/presentation/pages/help_support_screen.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shared CustomAppBar reads AuthStore (space chip) and
/// NotificationsStore (bell), so every screen needs both provided.
Widget _app(Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthStore>(
        create: (_) => AuthStore(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: false,
        ),
      ),
      ChangeNotifierProvider(create: (_) => NotificationsStore()),
    ],
    child: MaterialApp(home: home),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('help & support keeps only real entries', (tester) async {
    await tester.pumpWidget(_app(const HelpSupportScreen()));
    await tester.pump();

    expect(find.text('FAQs'), findsOneWidget);
    expect(find.text('Getting Started Guide'), findsOneWidget);
    expect(find.text('Email Support'), findsOneWidget);
    expect(find.text('Documentation'), findsOneWidget);

    expect(find.text('Live Chat'), findsNothing);
    expect(find.text('Report a Bug'), findsNothing);
    expect(find.text('Account & Privacy'), findsNothing);
    expect(find.textContaining('coming soon'), findsNothing);
  });

  test('FAQ covers the core vocabulary', () {
    final questions = faqEntries.map((e) => e.question.toLowerCase()).toList();
    for (final term in [
      'gem',
      'hunter',
      'update',
      'alpha radar',
      'edge brief',
      'mining',
      'bnp and bnt',
      'quests',
      'badges',
      'levels',
    ]) {
      expect(
        questions.any((q) => q.contains(term)),
        isTrue,
        reason: 'no FAQ question mentions "$term"',
      );
    }
  });

  testWidgets('FAQ tiles expand on tap', (tester) async {
    await tester.pumpWidget(_app(const FaqScreen()));
    await tester.pump();

    final first = faqEntries.first;
    expect(find.text(first.question), findsOneWidget);
    expect(find.text(first.answer), findsNothing);

    await tester.tap(find.text(first.question));
    await tester.pumpAndSettle();

    expect(find.text(first.answer), findsOneWidget);
  });

  testWidgets('getting started lists every step in order', (tester) async {
    await tester.pumpWidget(_app(const GettingStartedScreen()));
    await tester.pump();

    for (var i = 0; i < gettingStartedSteps.length; i++) {
      final step = gettingStartedSteps[i];
      await tester.scrollUntilVisible(
        find.text('${i + 1}. ${step.title}'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('${i + 1}. ${step.title}'), findsOneWidget);
    }
  });
}
