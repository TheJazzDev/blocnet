import 'package:flutter/material.dart';
import 'package:blocknet/features/auth/routes.dart';
import 'package:blocknet/features/projects/routes.dart';

class CustomAppRouter {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      ...AuthRoutes.getAll(),
      ...ProjectRoutes.getAll(),
    };
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routes = getRoutes();

    final builder = routes[settings.name];

    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Page not found')),
      ),
    );
  }
}
