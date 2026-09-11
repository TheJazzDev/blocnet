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

  /// Bottom-tab indices shared by every space. Discover is 1 in the user,
  /// hunter and moderation shells alike.
  static const int homeTab = 0;
  static const int discoverTab = 1;

  final ValueChanged<int> selectTab;

  static MainTabScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainTabScope>();
  }

  @override
  bool updateShouldNotify(MainTabScope oldWidget) =>
      selectTab != oldWidget.selectTab;
}
