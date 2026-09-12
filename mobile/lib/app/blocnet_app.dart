import 'package:blocnet/app/theme.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/shared/pages/page_not_found.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The themed application root.
class BlocnetApp extends StatelessWidget {
  const BlocnetApp({
    super.key,
    required this.navigatorKey,
    required this.initialRoute,
    required this.onGenerateRoute,
    this.onGenerateInitialRoutes,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final String initialRoute;
  final RouteFactory onGenerateRoute;
  final InitialRouteListFactory? onGenerateInitialRoutes;

  @override
  Widget build(BuildContext context) {
    // Selector, not Consumer: AuthStore notifies from ~56 places and the root
    // depends on exactly one bit of it. A Consumer here rebuilt MaterialApp,
    // rebuilt the theme and dirtied the navigator subtree on every one.
    return Selector<AuthStore, bool>(
      selector: (_, auth) => auth.isInHunterSpace,
      builder: (context, isInHunterSpace, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildPrimaryTheme(
          accent: AppColors.accentForSpace(isInHunterSpace),
        ),
        navigatorKey: navigatorKey,
        onGenerateRoute: onGenerateRoute,
        onGenerateInitialRoutes: onGenerateInitialRoutes,
        initialRoute: initialRoute,
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => const PageNotFoundScreen(),
        ),
      ),
    );
  }
}
