import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/email_link_handler_page.dart';
import '../../screen/main_screen.dart';
import '../../features/projects/presentation/sections/home.dart';
import '../../features/projects/presentation/sections/explore/explore.dart';
import '../../features/projects/presentation/sections/explore/trending.dart';
import '../../features/projects/presentation/sections/explore/priority.dart';
import '../../features/projects/presentation/sections/projects/discover.dart';
import '../../screen/notifications.dart';
import '../../screen/profile_screen.dart';
import '../../screen/settings_screen.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth routes
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case RouteNames.signIn:
        return MaterialPageRoute(builder: (_) => const SignInPage());

      case RouteNames.emailLink:
        final emailLink = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => EmailLinkHandlerPage(emailLink: emailLink),
        );

      // Main app routes
      case RouteNames.main:
        return MaterialPageRoute(builder: (_) => const MainScreen());

      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case RouteNames.explore:
        return MaterialPageRoute(
          builder: (_) => ExploreSection(allPosts: const []),
        );

      case RouteNames.trending:
        return MaterialPageRoute(builder: (_) => const TrendingScreen());

      case RouteNames.discover:
        return MaterialPageRoute(builder: (_) => const DiscoverScreen());

      case RouteNames.priority:
        return MaterialPageRoute(builder: (_) => const PriorityScreens());

      // Profile & Settings
      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case RouteNames.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case RouteNames.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      // Default - 404
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(
              child: Text('404 - Page Not Found'),
            ),
          ),
        );
    }
  }
}
