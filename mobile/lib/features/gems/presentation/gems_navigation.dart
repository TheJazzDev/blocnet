import 'package:blocnet/features/gems/domain/gems_tab.dart';
import 'package:blocnet/features/main/presentation/navigation/main_tab_navigator.dart';
import 'package:blocnet/features/main/presentation/widgets/main_tab_redirect.dart';
import 'package:blocnet/features/main/presentation/widgets/main_tab_scope.dart';
import 'package:flutter/widgets.dart';

/// Opens the Gems tab on a chosen view from anywhere in the app.
///
/// ```dart
/// GemsNavigation.open(context, tab: GemsTab.board);
/// ```
///
/// Inside the main shell it switches the bottom tab; above it (a pushed
/// page, a sheet) it pops back to the shell first; with no shell open it
/// pushes the tab's named route (`/gems`, `/gems/board`, `/gems/hunters`).
class GemsNavigation {
  GemsNavigation._();

  static final GemsTabRequests requests = GemsTabRequests();

  static void open(BuildContext context, {GemsTab tab = GemsTab.discover}) {
    requests.push(tab);
    MainTabNavigator.open(
      context,
      MainTabScope.discoverTab,
      fallbackRoute: tab.route,
    );
  }
}

/// The view the next Gems screen to look should open on.
class GemsTabRequests extends ChangeNotifier {
  GemsTab? _pending;

  void push(GemsTab tab) {
    _pending = tab;
    notifyListeners();
  }

  /// Returns and clears the pending view.
  GemsTab? take() {
    final tab = _pending;
    _pending = null;
    return tab;
  }
}

/// What `/gems`, `/gems/board`, `/gems/hunters`, `/discover` and
/// `/top-hunters` build: the Gems tab on [tab].
class GemsTabRedirect extends StatefulWidget {
  const GemsTabRedirect({super.key, required this.tab});

  final GemsTab tab;

  @override
  State<GemsTabRedirect> createState() => _GemsTabRedirectState();
}

class _GemsTabRedirectState extends State<GemsTabRedirect> {
  @override
  void initState() {
    super.initState();
    GemsNavigation.requests.push(widget.tab);
  }

  @override
  Widget build(BuildContext context) {
    return const MainTabRedirect(tab: MainTabScope.discoverTab);
  }
}
