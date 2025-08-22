import 'package:blocnet/features/projects/presentation/sections/home.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/screen/profile_screen.dart';
import 'package:blocnet/screen/settings_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> pages = [
    const HomeScreen(),
    const ProfileScreen(),
    const SettingsScreen()
  ];

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], 
      appBar: const CustomAppBar(title: 'Blocnet'),
      body: pages[currentPage],
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentPage,
          onTap: (value) {
            setState(() {
              currentPage = value;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Settings')
          ]),
    );
  }
}
