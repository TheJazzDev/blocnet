import 'package:blocnet/features/auth/presentation/pages/closed_alpha_screen.dart';
import 'package:blocnet/features/auth/presentation/pages/sign_in.dart';
import 'package:blocnet/features/auth/presentation/pages/sign_up.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_feedback.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers the closed-alpha check with a fixed verdict.
class _AlphaApiClient extends ApiClient {
  _AlphaApiClient({required this.allowed});

  bool allowed;
  final List<String> paths = [];

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    paths.add(path);
    if (path == '/public/closed-alpha/check') {
      return {'enabled': true, 'allowed': allowed};
    }
    return <String, dynamic>{};
  }
}

AuthStore _store(_AlphaApiClient api) => AuthStore(
      apiClient: api,
      enableSupabaseAuthListener: false,
      supabaseConfiguredOverride: true,
    );

Widget _app(AuthStore store, Widget home) {
  return ChangeNotifierProvider<AuthStore>.value(
    value: store,
    child: MaterialApp(
      home: home,
      routes: {
        ClosedAlphaScreen.routeName: (_) => const ClosedAlphaScreen(),
      },
    ),
  );
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('sign in fits a 375px phone without overflow', (tester) async {
    _phone(tester);
    final store = _store(_AlphaApiClient(allowed: true));
    await tester.pumpWidget(_app(store, const SignInScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sign in to Blocnet'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);

    // Validation errors must also fit.
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign up fits a 375px phone without overflow', (tester) async {
    _phone(tester);
    final store = _store(_AlphaApiClient(allowed: true));
    await tester.pumpWidget(_app(store, const SignUpScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Join Blocnet'), findsOneWidget);
    expect(find.text('Referral code (optional)'), findsOneWidget);
  });

  testWidgets('closed-alpha screen fits 375px and offers next steps',
      (tester) async {
    _phone(tester);
    final store = _store(_AlphaApiClient(allowed: false));
    await tester.pumpWidget(
      _app(store, const ClosedAlphaScreen(email: 'tester@example.com')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Not on the list yet'), findsOneWidget);
    expect(find.text('tester@example.com'), findsOneWidget);
    expect(find.text('NOT INVITED'), findsOneWidget);
    expect(find.text('Ask for an invite'), findsOneWidget);
    expect(
        find.text('Email ${ClosedAlphaScreen.supportEmail}'), findsOneWidget);
    expect(find.text('Use a different email'), findsOneWidget);
  });

  testWidgets('a rejected email opens the closed-alpha screen, not a snackbar',
      (tester) async {
    _phone(tester);
    final api = _AlphaApiClient(allowed: false);
    final store = _store(api);
    await tester.pumpWidget(_app(store, const SignInScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'Outsider@Example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(api.paths, contains('/public/closed-alpha/check'));
    expect(store.closedAlphaRejected, isTrue);
    expect(find.byType(ClosedAlphaScreen), findsOneWidget);
    expect(find.text('outsider@example.com'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    // "Use a different email" goes back to the form.
    await tester.tap(find.text('Use a different email'));
    await tester.pumpAndSettle();
    expect(find.byType(ClosedAlphaScreen), findsNothing);
    expect(find.text('Sign in to Blocnet'), findsOneWidget);
  });

  test('a new attempt clears an earlier closed-alpha rejection', () async {
    final api = _AlphaApiClient(allowed: false);
    final store = _store(api);

    await store.signInWithEmailPassword(email: 'a@b.co', password: 'x');
    expect(store.closedAlphaRejectedEmail, 'a@b.co');

    api.allowed = true;
    // Supabase is not initialised in tests, so this still fails, but past
    // the allowlist: the rejection must not linger.
    await store.signInWithEmailPassword(email: 'a@b.co', password: 'x');
    expect(store.closedAlphaRejected, isFalse);
  });

  test('raw exception text is replaced with the fallback', () {
    expect(authErrorText(null, 'Fallback'), 'Fallback');
    expect(
      authErrorText('Exception: SocketException: failed', 'Fallback'),
      'Fallback',
    );
    expect(authErrorText('Invalid login credentials', 'Fallback'),
        'Invalid login credentials');
  });
}
