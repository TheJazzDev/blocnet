part of '../main_screen.dart';

const _userTabs = [
  _TabMeta(
    title: 'Blocnet',
    showSearch: true,
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
    title: 'Mining',
    showSearch: true,
    showFilter: false,
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
    showSearch: true,
    showFilter: false,
    showNotificationBell: false,
  ),
];

const _hunterTabs = [
  _TabMeta(
    title: 'Blocnet',
    showSearch: true,
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
    title: 'Mining',
    showSearch: true,
    showFilter: false,
    showNotificationBell: false,
  ),
  _TabMeta(
    title: 'Hunter Hub',
    showSearch: true,
    showFilter: false,
    showNotificationBell: false,
  ),
  _TabMeta(
    title: 'Wallet',
    showSearch: true,
    showFilter: false,
    showNotificationBell: false,
  ),
];

class _UserSpaceShell extends StatelessWidget {
  const _UserSpaceShell({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
  });

  final int currentIndex;
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
        showNotificationBell: tab.showNotificationBell,
        showProfileShortcut: false,
        showProfileAvatarLeading: currentIndex == 0,
      ),
      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeScreen(),
          DiscoverScreen(),
          MiningScreen(),
          CommunityScreen(),
          WalletScreen(),
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
    required this.onNavTap,
    required this.onFabTap,
  });

  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final VoidCallback onFabTap;

  @override
  Widget build(BuildContext context) {
    final tab = _hunterTabs[currentIndex];
    final showComposerFab =
        currentIndex == 0 || currentIndex == 1 || currentIndex == 3;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: CustomAppBar(
        title: tab.title,
        backButton: false,
        showSearch: tab.showSearch,
        showFilter: tab.showFilter,
        showNotificationBell: tab.showNotificationBell,
        showProfileShortcut: false,
        showProfileAvatarLeading: currentIndex == 0,
      ),
      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeScreen(),
          DiscoverScreen(),
          MiningScreen(),
          HunterHubScreen(),
          WalletScreen(),
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
