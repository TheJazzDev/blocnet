import 'package:blocnet/app/router.dart';
import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/services/admins_store.dart';
import 'package:blocnet/services/app_store.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/badges_store.dart';
import 'package:blocnet/services/blocks_store.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/deep_link_service.dart';
import 'package:blocnet/services/edge_engine_store.dart';
import 'package:blocnet/services/feed_view_mode_store.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:blocnet/services/notification_settings_store.dart';
import 'package:blocnet/services/push_notification_service.dart';
import 'package:blocnet/services/quests_store.dart';
import 'package:blocnet/services/tips_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/services/tags_store.dart';
import 'package:blocnet/services/comments_store.dart';
import 'package:blocnet/services/community_posts_store.dart';
import 'package:blocnet/services/mining_store.dart';
import 'package:blocnet/services/user_profile_store.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
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
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

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
      ),
    );
  }

  final authStore = AuthStore();
  await authStore.bootstrapFromSession();
  final notificationsStore = NotificationsStore();
  final notificationSettingsStore = NotificationSettingsStore();
  final initialRoute =
      authStore.isAuthenticated ? AppRoutes.main : AppRoutes.signIn;

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Future.delayed(Duration(seconds: 3));
  FlutterNativeSplash.remove();

  // Initialise deep link handling (email verify, magic link, password reset)
  final deepLinkService = DeepLinkService(
    navigatorKey: _navigatorKey,
    authStore: authStore,
  );
  deepLinkService.init();

  // Initialise push notifications tied to auth state.
  // - If already authenticated on cold start: init immediately.
  // - If the user signs in later (or signs out): react via listener.
  final pushNotificationService = PushNotificationService(
    onForegroundMessage: () {
      notificationsStore.refreshNotifications();
    },
  );
  bool pushInitialised = false;

  void onAuthChanged() {
    if (authStore.isAuthenticated && !pushInitialised) {
      pushInitialised = true;
      pushNotificationService.init();
    } else if (!authStore.isAuthenticated && pushInitialised) {
      pushInitialised = false;
      pushNotificationService.dispose();
      notificationSettingsStore.clear();
    }
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
        ChangeNotifierProvider(create: (_) => AppStore()),
        ChangeNotifierProvider(create: (_) => UpdatesStore()),
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
        ChangeNotifierProvider(create: (_) => MiningStore()),
        ChangeNotifierProvider(create: (_) => UserProfileStore()),
        ChangeNotifierProvider(create: (_) => TipsStore()),
        ChangeNotifierProvider(create: (_) => WalletStore()),
        ChangeNotifierProvider(create: (_) => BlocksStore(ApiClient())),
        ChangeNotifierProvider(create: (_) => TagsStore()),
        ChangeNotifierProvider(create: (_) => AdminsStore()),
        ChangeNotifierProvider(create: (_) => BadgesStore()),
        ChangeNotifierProxyProvider<AuthStore, QuestsStore>(
          create: (_) => QuestsStore(),
          update: (_, auth, questsStore) {
            final store = questsStore ?? QuestsStore();
            store.ensureUserScope(auth.userId);
            return store;
          },
        ),
        // ChangeNotifierProvider(create: (_) => PriorityStore()),
        ChangeNotifierProvider(create: (_) => ProjectsStore()),
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
}
