import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/screen/main_screen.dart';
import 'package:flutter/material.dart';
import '../screen/notifications.dart';
import '../features/projects/presentation/sections/explore/trending.dart';
import '../features/projects/presentation/sections/explore/priority.dart';

class ProtectedRoutes {
  // Global
  static const String main = AppRoutes.main;
  static const String profile = AppRoutes.profile;
  static const String settings = AppRoutes.settings;
  static const String notifications = AppRoutes.notifications;

  // Projects
  static const String home = AppRoutes.home;
  static const String discover = AppRoutes.discover;
  static const String trending = AppRoutes.trending;
  static const String midPriority = AppRoutes.midPriority;
  static const String lowPriority = AppRoutes.lowPriority;
  static const String highPriority = AppRoutes.highPriority;

  static bool isProtectedRoute(String? route) {
    if (route == null) return false;
    return _allRoutes.contains(route);
  }

  static Map<String, WidgetBuilder> getAll() {
    return {
      // Global
      main: (context) => const MainScreen(initialIndex: 0),
      profile: (context) => const MainScreen(initialIndex: 2),
      settings: (context) => const MainScreen(initialIndex: 3),

      // Projects
      home: (context) => const MainScreen(initialIndex: 0),
      discover: (context) => const MainScreen(initialIndex: 1),
      trending: (context) => const TrendingScreen(),
      midPriority: (context) => const PriorityScreens(),
      lowPriority: (context) => const PriorityScreens(),
      highPriority: (context) => const PriorityScreens(),
      notifications: (context) => const NotificationsScreen(),
    };
  }

  static const Set<String> _allRoutes = {
    main,
    profile,
    settings,
    notifications,
    home,
    discover,
    trending,
    midPriority,
    lowPriority,
    highPriority,
  };
}
