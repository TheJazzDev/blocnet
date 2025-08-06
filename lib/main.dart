import 'package:blocnet/app/router.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/services/admins_store.dart';
import 'package:blocnet/services/app_store.dart';
import 'package:blocnet/services/posts_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'constants/app_routes.dart';
import 'screen/page_not_found.dart';
import 'package:provider/provider.dart';

// firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Future.delayed(Duration(seconds: 3));
  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStore()),
        ChangeNotifierProvider(create: (_) => PostsStore()),
        ChangeNotifierProvider(create: (_) => AdminsStore()),
        // ChangeNotifierProvider(create: (_) => PriorityStore()),
        ChangeNotifierProvider(create: (_) => ProjectsStore()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: primaryTheme,
        onGenerateRoute: CustomAppRouter.generateRoute,
        initialRoute: AppRoutes.signIn,
        onUnknownRoute: (settings) =>
            MaterialPageRoute(builder: (context) => const PageNotFoundScreen()),
      ),
    ),
  );
}
