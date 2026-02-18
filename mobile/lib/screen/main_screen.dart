import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/hunter/presentation/pages/hunter_hub_screen.dart';
import 'package:blocnet/features/projects/presentation/sections/home.dart';
import 'package:blocnet/features/projects/presentation/sections/projects/discover.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/screen/profile_screen.dart';
import 'package:blocnet/screen/wallet_screen.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late final PageController _userPageController;
  late final PageController _hunterPageController;

  // User space: 0=Home, 1=Discover, 2=Wallet, 3=Profile
  int _userIndex = 0;

  // Hunter space: 0=Home, 1=Discover, 2=Hub, 3=Profile
  int _hunterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userIndex = widget.initialIndex.clamp(0, 3);
    _hunterIndex = 0;
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
    final auth = context.watch<AuthStore>();
    final isHunterSpace = auth.isInHunterSpace;

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

  Future<void> _openComposerSheet(BuildContext context) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.borderMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CREATE',
                    style: GoogleFonts.inter(
                      color: AppColors.textFaint,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ComposerTile(
                  title: 'Post Hunter Update',
                  subtitle: 'Share intel about a project you track',
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.teal400,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushNamed(AppRoutes.createUpdate);
                  },
                ),
                const SizedBox(height: 8),
                _ComposerTile(
                  title: 'Submit New Gem',
                  subtitle: 'Propose a project to be listed on Blocnet',
                  icon: Icons.diamond_outlined,
                  iconColor: AppColors.primary400,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushNamed(AppRoutes.submitProject);
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

// ─────────────────────────────────────────────────────────────────────────────
// User Space Shell: Home | Discover | Wallet | Profile  (4 tabs)
// ─────────────────────────────────────────────────────────────────────────────

// Tab meta for user space
const _userTabs = [
  _TabMeta(
      title: 'Blocnet',
      showSearch: false,
      showFilter: false,
      showSpaceSwitcher: false,
      showNotificationBell: true),
  _TabMeta(
      title: 'Discover',
      showSearch: true,
      showFilter: true,
      showSpaceSwitcher: false,
      showNotificationBell: false),
  _TabMeta(
      title: 'Wallet',
      showSearch: false,
      showFilter: false,
      showSpaceSwitcher: false,
      showNotificationBell: false),
  _TabMeta(
      title: 'Profile',
      showSearch: false,
      showFilter: false,
      showSpaceSwitcher: false,
      showNotificationBell: false),
];

class _UserSpaceShell extends StatelessWidget {
  const _UserSpaceShell({
    super.key,
    required this.currentIndex,
    required this.pageController,
    required this.onNavTap,
  });

  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onNavTap;

  @override
  Widget build(BuildContext context) {
    final tab = _userTabs[currentIndex];
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: CustomAppBar(
        title: tab.title,
        backButton: false,
        showSearch: tab.showSearch,
        showFilter: tab.showFilter,
        showSpaceSwitcher: currentIndex == 3,
        showNotificationBell: tab.showNotificationBell,
      ),
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          HomeScreen(), // 0
          DiscoverScreen(), // 1
          WalletScreen(), // 2
          ProfileScreen(), // 3
        ],
      ),
      bottomNavigationBar: _UserNav(
        currentIndex: currentIndex,
        onTap: onNavTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hunter Space Shell: Home | Discover | [FAB] | Hub | Profile  (5 slots)
// ─────────────────────────────────────────────────────────────────────────────

// Tab meta for hunter space (index 2 is FAB — no app bar entry needed, uses index mapping 0,1,2,3)
const _hunterTabs = [
  _TabMeta(
      title: 'Blocnet',
      showSearch: false,
      showFilter: false,
      showSpaceSwitcher: false,
      showNotificationBell: true),
  _TabMeta(
      title: 'Discover',
      showSearch: true,
      showFilter: true,
      showSpaceSwitcher: false,
      showNotificationBell: false),
  _TabMeta(
      title: 'Hunter Hub',
      showSearch: false,
      showFilter: false,
      showSpaceSwitcher: false,
      showNotificationBell: true),
  _TabMeta(
      title: 'Profile',
      showSearch: false,
      showFilter: false,
      showSpaceSwitcher: false,
      showNotificationBell: false),
];

class _HunterSpaceShell extends StatelessWidget {
  const _HunterSpaceShell({
    super.key,
    required this.currentIndex,
    required this.pageController,
    required this.onNavTap,
    required this.onFabTap,
  });

  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onNavTap;
  final VoidCallback onFabTap;

  @override
  Widget build(BuildContext context) {
    final tab = _hunterTabs[currentIndex];
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: CustomAppBar(
        title: tab.title,
        backButton: false,
        showSearch: tab.showSearch,
        showFilter: tab.showFilter,
        showSpaceSwitcher: currentIndex == 3,
        showNotificationBell: tab.showNotificationBell,
      ),
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          HomeScreen(), // 0
          DiscoverScreen(), // 1
          HunterHubScreen(), // 2
          ProfileScreen(), // 3
        ],
      ),
      bottomNavigationBar: _HunterNav(
        currentIndex: currentIndex,
        onTap: onNavTap,
        onFabTap: onFabTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Nav Bar — 4 items
// ─────────────────────────────────────────────────────────────────────────────

class _UserNav extends StatelessWidget {
  const _UserNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationsStore>().unreadCount;

    return _NavContainer(
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore_rounded,
            label: 'Discover',
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            label: 'Wallet',
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            isActive: currentIndex == 3,
            badgeCount: unreadCount,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hunter Nav Bar — 5 slots (Home | Discover | FAB | Hub | Profile)
// ─────────────────────────────────────────────────────────────────────────────

class _HunterNav extends StatelessWidget {
  const _HunterNav({
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;

  @override
  Widget build(BuildContext context) {
    return _NavContainer(
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore_rounded,
            label: 'Discover',
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          // Centre FAB
          Expanded(
            child: GestureDetector(
              onTap: onFabTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -14),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary400,
                            AppColors.primary600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.bgBase,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary500.withValues(alpha: 0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _NavItem(
            icon: Icons.radar_outlined,
            activeIcon: Icons.radar_rounded,
            label: 'Hub',
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            isActive: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared nav container
// ─────────────────────────────────────────────────────────────────────────────

class _NavContainer extends StatelessWidget {
  const _NavContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single nav item
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary400 : AppColors.textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : icon, size: 21, color: color),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.bgSurface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Composer bottom sheet tile
// ─────────────────────────────────────────────────────────────────────────────

class _ComposerTile extends StatelessWidget {
  const _ComposerTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textFaint,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab metadata — drives the shared app bar per tab
// ─────────────────────────────────────────────────────────────────────────────

class _TabMeta {
  const _TabMeta({
    required this.title,
    required this.showSearch,
    required this.showFilter,
    required this.showSpaceSwitcher,
    required this.showNotificationBell,
  });

  final String title;
  final bool showSearch;
  final bool showFilter;
  final bool showSpaceSwitcher;
  final bool showNotificationBell;
}
