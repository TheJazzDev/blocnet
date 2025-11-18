import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/email_link_handler_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/theme_settings_page.dart';
import '../../features/settings/presentation/pages/notification_settings_page.dart';
import '../../features/settings/presentation/pages/account_settings_page.dart';
import '../../features/settings/presentation/pages/about_page.dart';
import '../../features/settings/presentation/pages/help_page.dart';
import '../../features/settings/presentation/pages/privacy_page.dart';
import '../../screen/main_screen.dart';
import '../../features/projects/presentation/sections/home.dart';
import '../../features/projects/presentation/sections/explore/explore.dart';
import '../../features/projects/presentation/sections/explore/trending.dart';
import '../../features/projects/presentation/sections/explore/priority.dart';
import '../../features/projects/presentation/sections/projects/discover.dart';
import '../../screen/notifications.dart';
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
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      case RouteNames.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfilePage());

      case RouteNames.settings:
        return MaterialPageRoute(builder: (_) => const SettingsMainPage());

      case RouteNames.themeSettings:
        return MaterialPageRoute(builder: (_) => const ThemeSettingsPage());

      case RouteNames.notificationSettings:
        return MaterialPageRoute(
            builder: (_) => const NotificationSettingsPage());

      case RouteNames.accountSettings:
        return MaterialPageRoute(builder: (_) => const AccountSettingsPage());

      case RouteNames.about:
        return MaterialPageRoute(builder: (_) => const AboutPage());

      case RouteNames.help:
        return MaterialPageRoute(builder: (_) => const HelpPage());

      case RouteNames.privacy:
        return MaterialPageRoute(builder: (_) => const PrivacyPage());

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
