import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/routes.dart';
import 'package:blocnet/app/route_access_gate.dart';
import 'package:blocnet/routes/protected_routes.dart';
import 'package:blocnet/services/auth_store.dart';

class CustomAppRouter {
  static Map<String, WidgetBuilder> getRoutes() {
    return {...AuthRoutes.getAll(), ...ProtectedRoutes.getAll()};
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name;
    final routes = getRoutes();

    final builder = routes[routeName];

    if (builder != null) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) {
          final isAuthenticated = context.watch<AuthStore>().isAuthenticated;
          final roles = context.watch<AuthStore>().roles;

          if (ProtectedRoutes.isProtectedRoute(routeName)) {
            if (!isAuthenticated) {
              return RouteAccessGate(
                allowAccess: false,
                redirectTo: AppRoutes.signIn,
                childBuilder: builder,
              );
            }

            final hasRoleAccess =
                ProtectedRoutes.hasRoleAccess(routeName, roles);
            return RouteAccessGate(
              allowAccess: hasRoleAccess,
              redirectTo: AppRoutes.main,
              childBuilder: builder,
            );
          }

          if (AuthRoutes.isGuestOnlyRoute(routeName)) {
            return RouteAccessGate(
              allowAccess: !isAuthenticated,
              redirectTo: AppRoutes.main,
              childBuilder: builder,
            );
          }

          return builder(context);
        },
      );
    }

    return MaterialPageRoute(
      builder: (_) =>
          const Scaffold(body: Center(child: Text('Page not found'))),
    );
  }
}
