import 'package:blocnet/app/router.dart';
import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/services/admins_store.dart';
import 'package:blocnet/services/app_store.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/notifications_store.dart';
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
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        onGenerateRoute: CustomAppRouter.generateRoute,
        initialRoute: initialRoute,
        onUnknownRoute: (settings) =>
            MaterialPageRoute(builder: (context) => const PageNotFoundScreen()),
      ),
    ),
  );
}
