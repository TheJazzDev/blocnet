import 'package:blocknet/app/router.dart';
import 'package:blocknet/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'constants/app_routes.dart';
import 'screen/page_not_found.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Future.delayed(Duration(seconds: 3));

  FlutterNativeSplash.remove();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: primaryTheme,
      onGenerateRoute: CustomAppRouter.generateRoute,
      initialRoute: AppRoutes.signIn,
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const PageNotFoundScreen(),
      ),
    ),
  );
}

class Sandbox extends StatelessWidget {
  const Sandbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sandbox'),
        centerTitle: true,
        backgroundColor: AppColors.darkGrey50,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: const Text('Sandbox'),
      ),
    );
  }
}
