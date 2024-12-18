import 'package:blocknet/app/router.dart';
import 'package:blocknet/app/theme.dart';
// import 'package:blocknet/features/projects/presentation/pages/home.dart';
// import 'package:blocknet/screens/notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

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
        initialRoute: '/signin'),
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
