import 'package:blocnet/constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'presentation/pages/home.dart';
import 'presentation/pages/notifications.dart';
import 'presentation/pages/explore/trending.dart';
import 'presentation/pages/explore/priority.dart';
import 'presentation/pages/projects/discover.dart';

class ProjectRoutes {
  static const String home = AppRoutes.home;
  static const String discover = AppRoutes.discover;
  static const String trending = AppRoutes.trending;
  static const String midPriority = AppRoutes.midPriority;
  static const String lowPriority = AppRoutes.lowPriority;
  static const String highPriority = AppRoutes.highPriority;
  static const String notifications = AppRoutes.notifications;

  static Map<String, WidgetBuilder> getAll() {
    return {
      home: (context) => const HomeScreen(),
      discover: (context) => const DiscoverScreen(),
      trending: (context) => const TrendingScreen(),
      midPriority: (context) => const PriorityScreens(),
      lowPriority: (context) => const PriorityScreens(),
      highPriority: (context) => const PriorityScreens(),
      notifications: (context) => const NotificationsScreen(),
    };
  }
}
