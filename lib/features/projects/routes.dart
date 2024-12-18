import 'package:blocknet/features/projects/presentation/pages/home.dart';
import 'package:blocknet/features/projects/presentation/pages/notifications.dart';
import 'package:flutter/material.dart';

class ProjectRoutes {
  static const String home = '/home';
  static const String notifications = '/notifications';

  static Map<String, WidgetBuilder> getAll() {
    return {
      home: (context) => const HomeScreen(),
      notifications: (context) => const NotificationsScreen(),
    };
  }
}
