part of '../main_screen.dart';

const _userTabs = [
  _TabMeta(
    title: 'Blocnet',
    showSearch: false,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Discover',
    showSearch: true,
    showFilter: true,
    showNotificationBell: false,
  ),
  _TabMeta(
    title: 'Community',
    showSearch: true,
    showFilter: false,
    showNotificationBell: false,
  ),
  _TabMeta(
    title: 'Wallet',
    showSearch: false,
    showFilter: false,
    showNotificationBell: false,
  ),
  _TabMeta(
    title: 'Profile',
    showSearch: false,
    showFilter: false,
    showNotificationBell: false,
  ),
];

const _hunterTabs = [
  _TabMeta(
    title: 'Blocnet',
    showSearch: false,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Discover',
    showSearch: true,
    showFilter: true,
    showNotificationBell: false,
  ),
  _TabMeta(
    title: 'Hunter Hub',
    showSearch: false,
    showFilter: false,
    showNotificationBell: false,
  ),
  _TabMeta(
    title: 'Wallet',
    showSearch: false,
    showFilter: false,
    showNotificationBell: false,
  ),
  _TabMeta(
    title: 'Profile',
    showSearch: false,
    showFilter: false,
    showNotificationBell: false,
  ),
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
        showSpaceSwitcher: currentIndex == 4,
        showNotificationBell: tab.showNotificationBell,
      ),
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          HomeScreen(),
          DiscoverScreen(),
          CommunityScreen(),
          WalletScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _UserNav(
        currentIndex: currentIndex,
        onTap: onNavTap,
      ),
    );
  }
}

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
    final showComposerFab =
        currentIndex == 0 || currentIndex == 1 || currentIndex == 2;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: CustomAppBar(
        title: tab.title,
        backButton: false,
        showSearch: tab.showSearch,
        showFilter: tab.showFilter,
        showSpaceSwitcher: currentIndex == 4,
        showNotificationBell: tab.showNotificationBell,
      ),
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          HomeScreen(),
          DiscoverScreen(),
          HunterHubScreen(),
          WalletScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _HunterNav(
        currentIndex: currentIndex,
        onTap: onNavTap,
      ),
      floatingActionButton:
          showComposerFab ? _FloatingComposerFab(onPressed: onFabTap) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
