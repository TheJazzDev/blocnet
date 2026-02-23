import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/hunter/presentation/pages/become_hunter_screen.dart';
import 'package:blocnet/features/hunter/presentation/pages/hunter_hub_screen.dart';
import 'package:blocnet/features/mining/presentation/pages/mining_downline_screen.dart';
import 'package:blocnet/features/mining/presentation/pages/mining_hourly_history_screen.dart';
import 'package:blocnet/features/mining/presentation/pages/mining_leaderboard_screen.dart';
import 'package:blocnet/features/projects/presentation/pages/create_update_screen.dart';
import 'package:blocnet/features/projects/presentation/pages/manage_updates_screen.dart';
import 'package:blocnet/features/projects/presentation/pages/manage_projects_screen.dart';
import 'package:blocnet/features/projects/presentation/pages/submit_project_screen.dart';
import 'package:blocnet/features/projects/presentation/pages/top_hunters_screen.dart';
import 'package:blocnet/features/tips/presentation/pages/tip_history_screen.dart';
import 'package:blocnet/screen/main_screen.dart';
import 'package:blocnet/screen/community_create_post_screen.dart';
import 'package:blocnet/screen/community_post_discussion_screen.dart';
import 'package:blocnet/screen/edit_profile_screen.dart';
import 'package:blocnet/screen/notifications.dart';
import 'package:blocnet/screen/profile_screen.dart';
import 'package:blocnet/screen/settings_screen.dart';
import 'package:blocnet/screen/wallet_screen.dart';
import 'package:flutter/material.dart';
import '../features/projects/presentation/sections/explore/trending.dart';
import '../features/projects/presentation/sections/explore/priority.dart';

class ProtectedRoutes {
  // Global
  static const String main = AppRoutes.main;
  static const String profile = AppRoutes.profile;
  static const String settings = AppRoutes.settings;
  static const String wallet = AppRoutes.wallet;
  static const String walletTransactions = AppRoutes.walletTransactions;
  static const String walletAssetDetail = AppRoutes.walletAssetDetail;
  static const String tipsHistory = AppRoutes.tipsHistory;
  static const String mining = AppRoutes.mining;
  static const String miningLeaderboard = AppRoutes.miningLeaderboard;
  static const String miningHourlyHistory = AppRoutes.miningHourlyHistory;
  static const String miningDownline = AppRoutes.miningDownline;
  static const String notifications = AppRoutes.notifications;
  static const String createUpdate = AppRoutes.createUpdate;
  static const String submitProject = AppRoutes.submitProject;
  static const String manageProjects = AppRoutes.manageProjects;
  static const String manageUpdates = AppRoutes.manageUpdates;
  static const String communityCreatePost = AppRoutes.communityCreatePost;
  static const String communityDiscussion = AppRoutes.communityDiscussion;
  static const String editProfile = AppRoutes.editProfile;

  // Hunter
  static const String hunterHub = AppRoutes.hunterHub;
  static const String becomeHunter = AppRoutes.becomeHunter;

  // Projects
  static const String home = AppRoutes.home;
  static const String discover = AppRoutes.discover;
  static const String trending = AppRoutes.trending;
  static const String midPriority = AppRoutes.midPriority;
  static const String lowPriority = AppRoutes.lowPriority;
  static const String highPriority = AppRoutes.highPriority;
  static const String topHunters = AppRoutes.topHunters;

  static bool isProtectedRoute(String? route) {
    if (route == null) return false;
    return _allRoutes.contains(route);
  }

  static bool hasRoleAccess(String? route, List<String> roles) {
    if (route == null) return false;
    final requiredRoles = _routeRoleAccess[route];
    if (requiredRoles == null || requiredRoles.isEmpty) return true;
    return roles.any(requiredRoles.contains);
  }

  static Map<String, WidgetBuilder> getAll() {
    return {
      // Global
      main: (context) => const MainScreen(initialIndex: 0),
      profile: (context) => const ProfileScreen(),
      settings: (context) => const SettingsScreen(),
      wallet: (context) => const WalletScreen(),
      walletTransactions: (context) =>
          const WalletScreen(showTransactionsOnly: true),
      walletAssetDetail: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final assetCode = args is Map ? args['assetCode']?.toString() : null;
        return WalletAssetDetailScreen(assetCode: assetCode ?? 'BNT');
      },
      tipsHistory: (context) => const TipHistoryScreen(),
      mining: (context) => const MainScreen(initialIndex: 4),
      miningLeaderboard: (context) => const MiningLeaderboardScreen(),
      miningHourlyHistory: (context) => const MiningHourlyHistoryScreen(),
      miningDownline: (context) => const MiningDownlineScreen(),
      // Notifications is now a push route (not a main tab)
      notifications: (context) => const NotificationsScreen(),
      createUpdate: (context) => const CreateUpdateScreen(),
      submitProject: (context) => const SubmitProjectScreen(),
      manageProjects: (context) => const ManageProjectsScreen(),
      manageUpdates: (context) => const ManageUpdatesScreen(),
      communityCreatePost: (context) => const CommunityCreatePostScreen(),
      communityDiscussion: (context) => const CommunityPostDiscussionScreen(),
      editProfile: (context) => const EditProfileScreen(),

      // Hunter
      hunterHub: (context) => const HunterHubScreen(),
      becomeHunter: (context) => const BecomeHunterScreen(),

      // Projects
      home: (context) => const MainScreen(initialIndex: 0),
      discover: (context) => const MainScreen(initialIndex: 1),
      trending: (context) => const TrendingScreen(),
      midPriority: (context) => const PriorityScreens(),
      lowPriority: (context) => const PriorityScreens(),
      highPriority: (context) => const PriorityScreens(),
      topHunters: (context) => const TopHuntersScreen(),
    };
  }

  static const Set<String> _allRoutes = {
    main,
    profile,
    settings,
    wallet,
    walletTransactions,
    walletAssetDetail,
    tipsHistory,
    mining,
    miningLeaderboard,
    miningHourlyHistory,
    miningDownline,
    notifications,
    createUpdate,
    submitProject,
    manageProjects,
    manageUpdates,
    communityCreatePost,
    communityDiscussion,
    editProfile,
    hunterHub,
    becomeHunter,
    home,
    discover,
    trending,
    midPriority,
    lowPriority,
    highPriority,
    topHunters,
  };

  static const Set<String> _contributorRoles = {
    'owner',
    'admin',
    'hunter',
  };

  static const Map<String, Set<String>> _routeRoleAccess = {
    createUpdate: _contributorRoles,
    submitProject: _contributorRoles,
    manageProjects: _contributorRoles,
    manageUpdates: _contributorRoles,
    hunterHub: _contributorRoles,
  };
}
