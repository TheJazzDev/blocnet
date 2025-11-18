import 'package:blocnet/app/theme.dart';
import 'package:blocnet/core/routes/app_router.dart';
import 'package:blocnet/core/routes/route_names.dart';
import 'package:blocnet/features/auth/presentation/providers/auth_provider.dart';
import 'package:blocnet/features/profile/presentation/providers/profile_provider.dart';
import 'package:blocnet/features/settings/presentation/providers/theme_provider.dart';
import 'package:blocnet/features/settings/presentation/providers/settings_provider.dart';
import 'package:blocnet/features/projects/presentation/providers/interactions_provider.dart';
import 'package:blocnet/services/admins_store.dart';
import 'package:blocnet/services/app_store.dart';
import 'package:blocnet/services/posts_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Future.delayed(const Duration(seconds: 2));
  FlutterNativeSplash.remove();

  runApp(const BlocNetApp());
}

class BlocNetApp extends StatelessWidget {
  const BlocNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Profile
        ChangeNotifierProvider(create: (_) => ProfileProvider()),

        // Settings
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),

        // Interactions
        ChangeNotifierProvider(create: (_) => InteractionsProvider()),

        // App State
        ChangeNotifierProvider(create: (_) => AppStore()),
        ChangeNotifierProvider(create: (_) => PostsStore()),
        ChangeNotifierProvider(create: (_) => AdminsStore()),
        ChangeNotifierProvider(create: (_) => ProjectsStore()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BlocNet',
        theme: primaryTheme,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: RouteNames.splash,
      ),
    );
  }
}
