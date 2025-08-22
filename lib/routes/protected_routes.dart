import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/screen/main_screen.dart';
import 'package:blocnet/screen/profile_screen.dart';
import 'package:blocnet/screen/settings_screen.dart';
import 'package:flutter/material.dart';
import '../features/projects/presentation/sections/home.dart';
import '../screen/notifications.dart';
import '../features/projects/presentation/sections/explore/trending.dart';
import '../features/projects/presentation/sections/explore/priority.dart';
import '../features/projects/presentation/sections/projects/discover.dart';

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

  static Map<String, WidgetBuilder> getAll() {
    return {
      // Global
      main: (context) => const MainScreen(),
      profile: (context) => const ProfileScreen(),
      settings: (context) => const SettingsScreen(),

      // Projects
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
