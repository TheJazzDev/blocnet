import 'package:blocknet/app/app_theme.dart';
import 'package:blocknet/features/projects/presentation/pages/home.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      theme: primaryTheme,
      routes: {
        '/homepage': (context) => const HomeScreen(),
      },
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
