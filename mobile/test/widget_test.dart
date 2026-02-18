import 'package:blocnet/features/auth/presentation/pages/sign_in.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Sign in screen renders auth content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthStore(),
        child: const MaterialApp(
          home: SignInScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sign in to Blocnet'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
