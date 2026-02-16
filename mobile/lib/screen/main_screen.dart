import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/presentation/sections/home.dart';
import 'package:blocnet/features/projects/presentation/sections/projects/discover.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:blocnet/screen/profile_screen.dart';
import 'package:blocnet/screen/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationsStore>().fetchNotificationsOnce();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    context.read<NotificationsStore>().refreshNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final canCreateUpdate = context.select<AuthStore, bool>(
      (store) => store.canCreateUpdate,
    );
    final showActionButton =
        (_currentIndex == 0 || _currentIndex == 1) && canCreateUpdate;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          if (_currentIndex == index) return;
          setState(() => _currentIndex = index);
        },
        children: const [
          HomeScreen(),
          DiscoverScreen(),
          _ProfileTabScreen(),
          _SettingsTabScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (value) {
          if (_currentIndex == value) return;
          _pageController.animateToPage(
            value,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
          );
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
      floatingActionButton: showActionButton
          ? FloatingActionButton(
              heroTag: 'composer-fab',
              onPressed: () =>
                  _openComposerSheet(canCreateUpdate: canCreateUpdate),
              backgroundColor: AppColors.primary500,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }

  Future<void> _openComposerSheet({
    required bool canCreateUpdate,
  }) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkGrey100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                if (canCreateUpdate)
                  _ComposerActionTile(
                    title: 'Create Update',
                    subtitle: 'Updates are created under approved projects',
                    icon: Icons.post_add_outlined,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(this.context)
                          .pushNamed(AppRoutes.createUpdate);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ComposerActionTile extends StatelessWidget {
  const _ComposerActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.darkGrey75,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkGrey200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.darkGrey700),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.darkGrey700,
            fontSize: 14,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppColors.darkGrey500,
            fontSize: 12,
            fontFamily: 'Geist',
          ),
        ),
      ),
    );
  }
}

class _ProfileTabScreen extends StatelessWidget {
  const _ProfileTabScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: const SafeArea(child: ProfileScreen()),
    );
  }
}

class _SettingsTabScreen extends StatelessWidget {
  const _SettingsTabScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: const SafeArea(child: SettingsScreen()),
    );
  }
}
