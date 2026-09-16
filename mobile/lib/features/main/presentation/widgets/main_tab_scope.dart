import 'package:flutter/widgets.dart';

/// Lets widgets inside the main shell's tab stack switch the active bottom
/// tab (e.g. an empty state that wants to send the user to Discover) without
/// pushing a new `MainScreen`.
///
/// Only descendants of `MainScreen` can see it; a page pushed on top of the
/// shell with `Navigator.push` must be given a callback by its launcher.
class MainTabScope extends InheritedWidget {
  const MainTabScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  /// Bottom-tab indices shared by every space. Only tab 2 differs between
  /// them (Community, Hunter Hub or Moderation).
  static const int homeTab = 0;
  static const int discoverTab = 1;
  static const int hubTab = 2;
  static const int miningTab = 3;
  static const int walletTab = 4;
  static const int profileTab = 5;

  final ValueChanged<int> selectTab;

  static MainTabScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainTabScope>();
  }

  @override
  bool updateShouldNotify(MainTabScope oldWidget) =>
      selectTab != oldWidget.selectTab;
}
