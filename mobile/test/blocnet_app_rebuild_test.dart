import 'package:blocnet/app/blocnet_app.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app root used to be a `Consumer<AuthStore>` wrapped around MaterialApp.
/// AuthStore calls notifyListeners from 56 places, but the root needs one bit
/// of it — the accent that follows hunter space — so every unrelated auth
/// change rebuilt MaterialApp, its theme and the navigator subtree.
///
/// A rebuild constructs a new MaterialApp widget, so widget identity is the
/// evidence: same instance means the root was left alone.
class _RolesAuthStore extends AuthStore {
  _RolesAuthStore({this.hunter = false})
      : super(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: false,
        );

  final bool hunter;

  @override
  bool get hasHunterSpace => hunter;
}

MaterialApp _root(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpRoot(WidgetTester tester, AuthStore auth) {
    return tester.pumpWidget(
      ChangeNotifierProvider<AuthStore>.value(
        value: auth,
        child: BlocnetApp(
          navigatorKey: GlobalKey<NavigatorState>(),
          initialRoute: '/',
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('home')),
          ),
        ),
      ),
    );
  }

  testWidgets('an auth change that leaves the accent alone does not rebuild '
      'the app root', (tester) async {
    final auth = _RolesAuthStore();
    await pumpRoot(tester, auth);
    final before = _root(tester);

    // A notify that does not touch isInHunterSpace.
    await auth.setPendingReferralCode('ABC123');
    await tester.pump();

    expect(identical(_root(tester), before), isTrue);
  });

  testWidgets('switching into hunter space does rebuild the app root',
      (tester) async {
    final auth = _RolesAuthStore(hunter: true);
    await pumpRoot(tester, auth);
    final before = _root(tester);

    auth.setActiveSpace('hunter');
    await tester.pump();

    expect(identical(_root(tester), before), isFalse);
  });

  testWidgets('the app root renders its initial route', (tester) async {
    await pumpRoot(tester, _RolesAuthStore());

    expect(find.text('home'), findsOneWidget);
  });
}
