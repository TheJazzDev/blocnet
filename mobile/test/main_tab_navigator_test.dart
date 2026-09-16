import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/main/presentation/navigation/main_tab_navigator.dart';
import 'package:blocnet/features/main/presentation/widgets/main_tab_redirect.dart';
import 'package:blocnet/features/main/presentation/widgets/main_tab_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for MainScreen: registers with the navigator hub and records
/// which tab it was asked to show.
class _FakeShell extends StatefulWidget {
  const _FakeShell({required this.selected});

  final List<int> selected;

  @override
  State<_FakeShell> createState() => _FakeShellState();
}

class _FakeShellState extends State<_FakeShell> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MainTabNavigator.attach(this, ModalRoute.of(context)!, widget.selected.add);
  }

  @override
  void dispose() {
    MainTabNavigator.detach(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('shell'));
  }
}

class _PushedPage extends StatelessWidget {
  const _PushedPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () => MainTabNavigator.openRoute(context, AppRoutes.wallet),
        child: const Text('open wallet'),
      ),
    );
  }
}

void main() {
  late List<int> selected;
  late GlobalKey<NavigatorState> navKey;

  Future<void> pumpShell(WidgetTester tester) async {
    selected = <int>[];
    navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: _FakeShell(selected: selected),
      ),
    );
  }

  testWidgets('a tab route lands on the open shell instead of stacking',
      (tester) async {
    await pumpShell(tester);

    navKey.currentState!.push(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (_, __, ___) =>
            const MainTabRedirect(tab: MainTabScope.walletTab),
      ),
    );
    await tester.pumpAndSettle();

    expect(selected, [MainTabScope.walletTab]);
    expect(navKey.currentState!.canPop(), isFalse);
    expect(find.text('shell'), findsOneWidget);
  });

  testWidgets('a page above the shell returns to it and selects the tab',
      (tester) async {
    await pumpShell(tester);

    navKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const _PushedPage()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open wallet'));
    await tester.pumpAndSettle();

    expect(selected, [MainTabScope.walletTab]);
    expect(navKey.currentState!.canPop(), isFalse);
  });

  test('every tab route maps to its bottom-tab index', () {
    expect(MainTabNavigator.tabForRoute, {
      AppRoutes.home: 0,
      AppRoutes.discover: 1,
      AppRoutes.mining: 3,
      AppRoutes.wallet: 4,
      AppRoutes.profile: 5,
    });
  });
}
