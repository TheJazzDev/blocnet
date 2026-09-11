import 'dart:async';

import 'package:blocnet/app/router.dart';
import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/badges_store.dart';
import 'package:blocnet/services/users/blocks_store.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/core/deep_link_service.dart';
import 'package:blocnet/services/edge/edge_engine_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/core/home_bootstrap_store.dart';
import 'package:blocnet/services/engagement/levels_store.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:blocnet/services/notifications/notification_settings_store.dart';
import 'package:blocnet/services/notifications/push_notification_service.dart';
import 'package:blocnet/services/notifications/notification_navigator.dart';
import 'package:blocnet/services/engagement/quests_store.dart';
import 'package:blocnet/services/engagement/tips_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/services/projects/project_invites_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/users/hunter_application_store.dart';
import 'package:blocnet/services/projects/tags_store.dart';
import 'package:blocnet/services/community/comments_store.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:blocnet/services/core/startup_metrics_service.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/services/wallet/wallet_visibility_store.dart';
import 'package:flutter/material.dart';
import 'constants/app_routes.dart';
import 'package:blocnet/shared/pages/page_not_found.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

// Must be top-level for firebase_messaging background handler.
// Delegate to the handler defined in push_notification_service.dart.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) =>
    firebaseMessagingBackgroundHandler(message);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  StartupMetricsService.markProcessStart();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register the background message handler before any other Firebase calls.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );
  }

  final authStore = AuthStore();
  final notificationsStore = NotificationsStore();
  final notificationSettingsStore = NotificationSettingsStore();
  final levelsStore = LevelsStore();
  final badgesStore = BadgesStore();
  final miningStore = MiningStore();
  final walletStore = WalletStore();
  final initialRoute = AppRoutes.main;

  // Initialise deep link handling (email verify, magic link, password reset)
  final deepLinkService = DeepLinkService(
    navigatorKey: _navigatorKey,
    authStore: authStore,
  );
  deepLinkService.init();

  // Initialise push notifications tied to auth state.
  // - If already authenticated on cold start: init immediately.
  // - If the user signs in later (or signs out): react via listener.
  bool pushInitialised = false;
  RemoteMessage? pendingNotificationTap;
  String? lastHandledTapKey;

  String notificationTapKey(RemoteMessage message) {
    final messageId = message.messageId?.trim();
    if (messageId != null && messageId.isNotEmpty) return messageId;
    final sentMillis = message.sentTime?.millisecondsSinceEpoch ?? 0;
    return '$sentMillis::${message.data.toString()}';
  }

  void handleNotificationTap(RemoteMessage message) {
    final context = _navigatorKey.currentContext;
    final authReady = authStore.isAuthenticated && !authStore.isBootstrapping;
    if (context == null || !authReady) {
      pendingNotificationTap = message;
      return;
    }

    final tapKey = notificationTapKey(message);
    if (lastHandledTapKey == tapKey) return;
    lastHandledTapKey = tapKey;
    unawaited(NotificationNavigator.handleNotificationTap(context, message));
  }

  void flushPendingNotificationTap() {
    final pending = pendingNotificationTap;
    if (pending == null) return;
    pendingNotificationTap = null;
    handleNotificationTap(pending);
  }

  void handleForegroundNotificationData(RemoteMessage message) {
    final notificationType = message.data['type']?.toString();
    if (notificationType == null) return;

    // Refresh appropriate stores based on notification type
    switch (notificationType) {
      case 'level_up':
        levelsStore.fetchMyProgress();
        break;
      case 'badge_earned':
        badgesStore.loadMyBadges(force: true);
        break;
      case 'mining_claimed':
      case 'referral_bound':
      case 'referral_admin_bound':
        miningStore.loadSnapshot(force: true);
        break;
      case 'quest_completed':
      case 'quest_verified':
      case 'quest_rejected':
        // QuestsStore will be refreshed via context in the UI
        // since it's a ProxyProvider that depends on AuthStore
        break;
      case 'wallet_transfer_sent':
      case 'wallet_transfer_received':
      case 'wallet_deposit_credited':
      case 'wallet_withdrawal_requested':
      case 'wallet_withdrawal_approved':
      case 'wallet_withdrawal_rejected':
      case 'wallet_withdrawal_broadcasted':
      case 'wallet_withdrawal_confirmed':
      case 'wallet_withdrawal_reverted':
      case 'wallet_kyc_reviewed':
      case 'wallet_provision_ready':
      case 'wallet_provision_failed':
        walletStore.loadWalletSummary(force: true);
        walletStore.loadTransactions(force: true);
        break;
    }
  }

  final pushNotificationService = PushNotificationService(
    onForegroundMessage: () {
      notificationsStore.refreshNotifications(category: 'all');
    },
    onForegroundMessageWithData: handleForegroundNotificationData,
    onNotificationTap: handleNotificationTap,
  );

  // Unregister the device token while the session is still valid, otherwise
  // the phone keeps receiving push for the signed-out account.
  authStore.onBeforeSignOut = pushNotificationService.unregisterCurrentToken;

  void onAuthChanged() {
    if (authStore.isAuthenticated && !pushInitialised) {
      pushInitialised = true;
      pushNotificationService.init();
    } else if (!authStore.isAuthenticated && pushInitialised) {
      pushInitialised = false;
      pushNotificationService.dispose();
      notificationSettingsStore.clear();
      pendingNotificationTap = null;
      lastHandledTapKey = null;
    }
    flushPendingNotificationTap();
  }

  authStore.addListener(onAuthChanged);

  // Trigger immediately in case the user is already authenticated.
  if (authStore.isAuthenticated) {
    pushInitialised = true;
    pushNotificationService.init();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthStore>.value(value: authStore),
        ChangeNotifierProvider(create: (_) => UpdatesStore()),
        // Eager so the Home bootstrap cache is read before the Home tab
        // builds; that is what lets it paint on the first frame.
        ChangeNotifierProvider(
          create: (_) => HomeBootstrapStore()..warmUp(),
          lazy: false,
        ),
        ChangeNotifierProvider(create: (_) => FeedViewModeStore()),
        ChangeNotifierProvider(create: (_) => CommunityPostsStore()),
        ChangeNotifierProvider(create: (_) => EdgeEngineStore()),
        ChangeNotifierProvider<NotificationsStore>.value(
          value: notificationsStore,
        ),
        ChangeNotifierProvider<NotificationSettingsStore>.value(
          value: notificationSettingsStore,
        ),
        ChangeNotifierProvider(create: (_) => CommentsStore()),
        ChangeNotifierProvider<MiningStore>.value(value: miningStore),
        ChangeNotifierProvider(create: (_) => UserProfileStore()),
        ChangeNotifierProvider(create: (_) => TipsStore()),
        ChangeNotifierProvider<WalletStore>.value(value: walletStore),
        ChangeNotifierProvider(create: (_) => WalletVisibilityStore()),
        ChangeNotifierProvider(create: (_) => BlocksStore(ApiClient())),
        ChangeNotifierProvider(create: (_) => TagsStore()),
        ChangeNotifierProvider<BadgesStore>.value(value: badgesStore),
        ChangeNotifierProvider<LevelsStore>.value(value: levelsStore),
        ChangeNotifierProxyProvider<AuthStore, QuestsStore>(
          create: (_) => QuestsStore(),
          update: (_, auth, questsStore) {
            final store = questsStore ?? QuestsStore();
            store.ensureUserScope(auth.userId);
            return store;
          },
        ),
        ChangeNotifierProvider(create: (_) => ProjectsStore()),
        ChangeNotifierProvider(create: (_) => ProjectInvitesStore()),
        ChangeNotifierProxyProvider<AuthStore, HunterApplicationStore>(
          create: (_) => HunterApplicationStore(),
          update: (_, auth, store) {
            final applicationStore = store ?? HunterApplicationStore();
            applicationStore.ensureUserScope(
              auth.userId,
              isHunter: auth.hasHunterSpace,
            );
            return applicationStore;
          },
        ),
      ],
      child: Consumer<AuthStore>(
        builder: (context, auth, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildPrimaryTheme(
            accent: AppColors.accentForSpace(auth.isInHunterSpace),
          ),
          navigatorKey: _navigatorKey,
          onGenerateRoute: CustomAppRouter.generateRoute,
          onGenerateInitialRoutes: CustomAppRouter.generateInitialRoutes,
          initialRoute: initialRoute,
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (context) => const PageNotFoundScreen(),
          ),
        ),
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    flushPendingNotificationTap();
    StartupMetricsService.markFirstFrame();
    authStore.markShellReady();
    authStore.startBackgroundBootstrap();
  });
}
