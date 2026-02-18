import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/hunter/presentation/pages/hunter_hub_screen.dart';
import 'package:blocnet/features/projects/presentation/sections/home.dart';
import 'package:blocnet/features/projects/presentation/sections/projects/discover.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/screen/community_screen.dart';
import 'package:blocnet/screen/profile_screen.dart';
import 'package:blocnet/screen/wallet_screen.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

part 'main/main_screen_shells.part.dart';
part 'main/main_screen_nav.part.dart';
part 'main/main_screen_composer.part.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late final PageController _userPageController;
  late final PageController _hunterPageController;

  int _userIndex = 0;
  int _hunterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userIndex = widget.initialIndex.clamp(0, 4);
    _hunterIndex = widget.initialIndex.clamp(0, 4);
    _userPageController = PageController(initialPage: _userIndex);
    _hunterPageController = PageController(initialPage: _hunterIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationsStore>().fetchNotificationsOnce();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userPageController.dispose();
    _hunterPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    context.read<NotificationsStore>().refreshNotifications();
  }

  void _onUserNavTap(int pageIndex) {
    if (_userIndex == pageIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _userIndex = pageIndex);
    _userPageController.jumpToPage(pageIndex);
  }

  void _onHunterNavTap(int pageIndex) {
    if (_hunterIndex == pageIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _hunterIndex = pageIndex);
    _hunterPageController.jumpToPage(pageIndex);
  }

  void _onFabTap(BuildContext context) {
    HapticFeedback.mediumImpact();
    _openComposerSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final isHunterSpace = context.watch<AuthStore>().isInHunterSpace;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: isHunterSpace
          ? _HunterSpaceShell(
              key: const ValueKey('hunter'),
              currentIndex: _hunterIndex,
              pageController: _hunterPageController,
              onNavTap: _onHunterNavTap,
              onFabTap: () => _onFabTap(context),
            )
          : _UserSpaceShell(
              key: const ValueKey('user'),
              currentIndex: _userIndex,
              pageController: _userPageController,
              onNavTap: _onUserNavTap,
            ),
    );
  }
}

class _TabMeta {
  const _TabMeta({
    required this.title,
    required this.showSearch,
    required this.showFilter,
    required this.showNotificationBell,
  });

  final String title;
  final bool showSearch;
  final bool showFilter;
  final bool showNotificationBell;
}
