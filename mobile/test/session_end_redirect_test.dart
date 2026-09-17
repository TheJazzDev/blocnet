import 'package:blocnet/app/route_access_gate.dart';
import 'package:blocnet/features/auth/presentation/widgets/session_ended_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PushCounter extends NavigatorObserver {
  final List<String?> pushed = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route.settings.name);
  }
}

void main() {
  testWidgets(
      'every gated screen losing auth at once routes to sign-in exactly once',
      (tester) async {
    final signedIn = ValueNotifier<bool>(true);
    final observer = _PushCounter();

    Route<dynamic> gated(RouteSettings settings) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => ValueListenableBuilder<bool>(
          valueListenable: signedIn,
          builder: (context, allowed, _) => RouteAccessGate(
            allowAccess: allowed,
            redirectTo: '/signin',
            childBuilder: (_) => Text('screen ${settings.name}'),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        initialRoute: '/main',
        onGenerateRoute: (settings) {
          if (settings.name == '/signin') {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Text('sign in'),
            );
          }
          return gated(settings);
        },
      ),
    );
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/profile');
    await tester.pumpAndSettle();
    observer.pushed.clear();

    signedIn.value = false;
    await tester.pumpAndSettle();

    expect(observer.pushed.where((name) => name == '/signin'), hasLength(1));
    expect(find.text('sign in'), findsOneWidget);
  });

  testWidgets('the session-ended notice shows its message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SessionEndedNotice(message: 'Your session ended. Sign in again.'),
        ),
      ),
    );

    expect(find.text('Your session ended. Sign in again.'), findsOneWidget);
  });
}
