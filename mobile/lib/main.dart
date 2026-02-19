import 'package:blocnet/app/router.dart';
import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/services/admins_store.dart';
import 'package:blocnet/services/app_store.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/deep_link_service.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:blocnet/services/push_notification_service.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/services/tags_store.dart';
import 'package:blocnet/services/comments_store.dart';
import 'package:blocnet/services/community_posts_store.dart';
import 'package:blocnet/services/user_profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'constants/app_routes.dart';
import 'screen/page_not_found.dart';
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
    );
  }

  final authStore = AuthStore();
  await authStore.bootstrapFromSession();
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
  final pushNotificationService = PushNotificationService();
  bool pushInitialised = false;

  void onAuthChanged() {
    if (authStore.isAuthenticated && !pushInitialised) {
      pushInitialised = true;
      pushNotificationService.init();
    } else if (!authStore.isAuthenticated && pushInitialised) {
      pushInitialised = false;
      pushNotificationService.dispose();
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
        ChangeNotifierProvider(create: (_) => CommunityPostsStore()),
        ChangeNotifierProvider(create: (_) => NotificationsStore()),
        ChangeNotifierProvider(create: (_) => CommentsStore()),
        ChangeNotifierProvider(create: (_) => UserProfileStore()),
        ChangeNotifierProvider(create: (_) => TagsStore()),
        ChangeNotifierProvider(create: (_) => AdminsStore()),
        // ChangeNotifierProvider(create: (_) => PriorityStore()),
        ChangeNotifierProvider(create: (_) => ProjectsStore()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: primaryTheme,
        navigatorKey: _navigatorKey,
        onGenerateRoute: CustomAppRouter.generateRoute,
        initialRoute: initialRoute,
        onUnknownRoute: (settings) =>
            MaterialPageRoute(builder: (context) => const PageNotFoundScreen()),
      ),
    ),
  );
}
