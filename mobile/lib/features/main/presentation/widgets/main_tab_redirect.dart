import 'package:blocnet/features/main/presentation/navigation/main_tab_navigator.dart';
import 'package:blocnet/features/main/presentation/pages/main_screen.dart';
import 'package:flutter/material.dart';

/// What a named tab route (`/wallet`, `/mining`, `/profile`, ...) builds.
///
/// With a `MainScreen` already open, this route removes itself and switches
/// that screen's tab, so deep links and notifications land on the real tab
/// instead of stacking a second copy (Wallet had no back button that way).
/// With none open, as on a cold-start deep link, it is the shell itself.
class MainTabRedirect extends StatefulWidget {
  const MainTabRedirect({super.key, required this.tab});

  final int tab;

  @override
  State<MainTabRedirect> createState() => _MainTabRedirectState();
}

class _MainTabRedirectState extends State<MainTabRedirect> {
  /// Decided once. The route builder rebuilds on every AuthStore change, and
  /// once this renders a shell that shell is itself the live one.
  bool? _redirect;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_redirect != null) return;
    final live = MainTabNavigator.liveRoute;
    _redirect = live != null && live != ModalRoute.of(context);
    if (_redirect!) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        if (!MainTabNavigator.returnTo(navigator, widget.tab)) {
          // The shell went away between build and this frame.
          setState(() => _redirect = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_redirect ?? false) return const SizedBox.shrink();
    return MainScreen(initialIndex: widget.tab);
  }
}
