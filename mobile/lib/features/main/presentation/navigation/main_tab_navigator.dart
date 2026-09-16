import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/main/presentation/widgets/main_tab_scope.dart';
import 'package:flutter/widgets.dart';

/// Lands on a bottom tab of the `MainScreen` that is already open, instead of
/// pushing a second copy of a tab screen on top of it.
///
/// [MainTabScope] only reaches widgets inside the shell. Pages pushed above
/// it (Help, Getting Started, a notification target) cannot see it, so each
/// live `MainScreen` also registers here with its route. [open] pops back to
/// that route and switches the tab.
class MainTabNavigator {
  MainTabNavigator._();

  /// Named routes that stand for a bottom tab.
  static const Map<String, int> tabForRoute = {
    AppRoutes.home: MainTabScope.homeTab,
    AppRoutes.discover: MainTabScope.discoverTab,
    AppRoutes.mining: MainTabScope.miningTab,
    AppRoutes.wallet: MainTabScope.walletTab,
    AppRoutes.profile: MainTabScope.profileTab,
  };

  static final List<_LiveShell> _shells = <_LiveShell>[];

  static void attach(
      Object owner, Route<dynamic> route, ValueChanged<int> selectTab) {
    _shells
      ..removeWhere((shell) => identical(shell.owner, owner))
      ..add(_LiveShell(owner, route, selectTab));
  }

  static void detach(Object owner) {
    _shells.removeWhere((shell) => identical(shell.owner, owner));
  }

  /// The newest shell still on a navigator. A shell being removed (for
  /// example by `pushNamedAndRemoveUntil`) no longer counts.
  static _LiveShell? get _live {
    for (final shell in _shells.reversed) {
      if (shell.route.isActive) return shell;
    }
    return null;
  }

  /// The route of the live shell, or null when none is open.
  static Route<dynamic>? get liveRoute => _live?.route;

  /// Pops back to the live shell and selects [tab]. Returns false when no
  /// shell is open on [navigator], so the caller can push one instead.
  static bool returnTo(NavigatorState navigator, int tab) {
    final shell = _live;
    if (shell == null || shell.route.navigator != navigator) return false;
    shell.selectTab(tab);
    navigator.popUntil((route) => route == shell.route);
    return true;
  }

  /// Opens [tab] from anywhere. Inside the shell it just switches tabs;
  /// above it, it pops back first; with no shell open it pushes [fallbackRoute].
  static void open(
    BuildContext context,
    int tab, {
    required String fallbackRoute,
  }) {
    // Called from tap handlers, so look up without subscribing.
    final scope = context.getInheritedWidgetOfExactType<MainTabScope>();
    if (scope != null) {
      scope.selectTab(tab);
      return;
    }
    final navigator = Navigator.of(context);
    if (!returnTo(navigator, tab)) {
      navigator.pushNamed(fallbackRoute);
    }
  }

  /// Pushes [route], unless it names a tab: then [open]s that tab.
  static void openRoute(BuildContext context, String route) {
    final tab = tabForRoute[route];
    if (tab == null) {
      Navigator.of(context).pushNamed(route);
      return;
    }
    open(context, tab, fallbackRoute: route);
  }
}

class _LiveShell {
  const _LiveShell(this.owner, this.route, this.selectTab);

  final Object owner;
  final Route<dynamic> route;
  final ValueChanged<int> selectTab;
}
