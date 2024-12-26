import 'package:blocknet/constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:blocknet/features/projects/presentation/pages/home.dart';
import 'package:blocknet/features/projects/presentation/pages/notifications.dart';
import 'package:blocknet/features/projects/presentation/pages/explore/trending.dart';
import 'presentation/pages/explore/priority.dart';

class ProjectRoutes {
  static const String home = AppRoutes.home;
  static const String trending = AppRoutes.trending;
  static const String midPriority = AppRoutes.midPriority;
  static const String lowPriority = AppRoutes.lowPriority;
  static const String highPriority = AppRoutes.highPriority;
  static const String notifications = AppRoutes.notifications;

  static Map<String, WidgetBuilder> getAll() {
    return {
      home: (context) => const HomeScreen(),
      trending: (context) => const TrendingScreen(),
      midPriority: (context) => const PriorityScreens(),
      lowPriority: (context) => const PriorityScreens(),
      highPriority: (context) => const PriorityScreens(),
      notifications: (context) => const NotificationsScreen(),
    };
  }
}
