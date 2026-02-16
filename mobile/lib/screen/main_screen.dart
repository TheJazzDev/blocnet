import 'package:blocnet/features/projects/presentation/sections/home.dart';
import 'package:blocnet/features/projects/presentation/sections/projects/discover.dart';
import 'package:blocnet/screen/profile_screen.dart';
import 'package:blocnet/screen/settings_screen.dart';
import 'package:flutter/material.dart';

enum _MainTab { home, projects, profile, settings }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late _MainTab _currentTab;

  @override
  void initState() {
    super.initState();
    final index = widget.initialIndex.clamp(0, _MainTab.values.length - 1);
    _currentTab = _MainTab.values[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildTabBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentTab.index,
        onTap: (value) {
          setState(() {
            _currentTab = _MainTab.values[value];
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Projects',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_currentTab) {
      case _MainTab.home:
        return const HomeScreen();
      case _MainTab.projects:
        return const DiscoverScreen();
      case _MainTab.profile:
        return const _ProfileTabScreen();
      case _MainTab.settings:
        return const _SettingsTabScreen();
    }
  }
}

class _ProfileTabScreen extends StatelessWidget {
  const _ProfileTabScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const SafeArea(child: ProfileScreen()),
    );
  }
}

class _SettingsTabScreen extends StatelessWidget {
  const _SettingsTabScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const SafeArea(child: SettingsScreen()),
    );
  }
}
