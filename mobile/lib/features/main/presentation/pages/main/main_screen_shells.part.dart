part of '../main_screen.dart';

const _userTabs = [
  _TabMeta(
    title: 'Home',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Discover',
    showSearch: true,
    showFilter: true,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Community',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Mining',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Wallet',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Profile',
    showSearch: false,
    showFilter: false,
    showNotificationBell: true,
  ),
];

const _hunterTabs = [
  _TabMeta(
    title: 'Home',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Discover',
    showSearch: true,
    showFilter: true,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Hub',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Mining',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Wallet',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Profile',
    showSearch: false,
    showFilter: false,
    showNotificationBell: true,
  ),
];

const _moderationTabs = [
  _TabMeta(
    title: 'Home',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Discover',
    showSearch: true,
    showFilter: true,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Moderation',
    showSearch: false,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Mining',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Wallet',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Profile',
    showSearch: false,
    showFilter: false,
    showNotificationBell: true,
  ),
];

class _UserSpaceShell extends StatelessWidget {
  const _UserSpaceShell({
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
    final tab = _userTabs[currentIndex];
    // Home and Discover only: the Community tab owns its own FAB.
    final showComposerFab = currentIndex == 0 || currentIndex == 1;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: CustomAppBar(
        title: tab.title,
        backButton: false,
        showSearch: tab.showSearch,
        showFilter: tab.showFilter,
        showSpaceSwitcher: true,
        showNotificationBell: tab.showNotificationBell,
        showProfileShortcut: false,
        showProfileAvatarLeading: false,
      ),
      body: LazyTabStack(
        index: currentIndex,
        builders: const [
          _homeBuilder,
          _discoverBuilder,
          _communityBuilder,
          _miningBuilder,
          _walletBuilder,
          _profileBuilder,
        ],
      ),
      bottomNavigationBar: SpaceBottomNav(
        space: NavSpace.user,
        currentIndex: currentIndex,
        onTap: onNavTap,
      ),
      floatingActionButton:
          showComposerFab ? _FloatingComposerFab(onPressed: onFabTap) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
    final isHub = currentIndex == MainTabScope.hubTab;
    final showComposerFab = currentIndex == 0 || currentIndex == 1;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: CustomAppBar(
        title: tab.title,
        backButton: false,
        showSearch: tab.showSearch,
        showFilter: tab.showFilter,
        showSpaceSwitcher: true,
        showNotificationBell: tab.showNotificationBell,
        showProfileShortcut: false,
        showProfileAvatarLeading: false,
        // D5: the Hub keeps the shared bar and adds My updates.
        actions: isHub ? const [HubHistoryAction()] : const [],
      ),
      body: LazyTabStack(
        index: currentIndex,
        builders: const [
          _homeBuilder,
          _discoverBuilder,
          _hunterHubBuilder,
          _miningBuilder,
          _walletBuilder,
          _profileBuilder,
        ],
      ),
      bottomNavigationBar: SpaceBottomNav(
        space: NavSpace.hunter,
        currentIndex: currentIndex,
        onTap: onNavTap,
      ),
      floatingActionButton: isHub
          ? const HubFabHost()
          : showComposerFab
              ? _FloatingComposerFab(onPressed: onFabTap)
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _ModerationSpaceShell extends StatelessWidget {
  const _ModerationSpaceShell({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
  });

  final int currentIndex;
  final ValueChanged<int> onNavTap;

  @override
  Widget build(BuildContext context) {
    final tab = _moderationTabs[currentIndex];

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: CustomAppBar(
        title: tab.title,
        backButton: false,
        showSearch: tab.showSearch,
        showFilter: tab.showFilter,
        showSpaceSwitcher: true,
        showNotificationBell: tab.showNotificationBell,
        showProfileShortcut: false,
        showProfileAvatarLeading: false,
      ),
      body: LazyTabStack(
        index: currentIndex,
        builders: const [
          _homeBuilder,
          _discoverBuilder,
          _moderationHubBuilder,
          _miningBuilder,
          _walletBuilder,
          _profileBuilder,
        ],
      ),
      bottomNavigationBar: SpaceBottomNav(
        space: NavSpace.moderation,
        currentIndex: currentIndex,
        onTap: onNavTap,
      ),
    );
  }
}

Widget _homeBuilder(BuildContext _) => const HomeScreen();
Widget _discoverBuilder(BuildContext _) => const DiscoverScreen();
Widget _communityBuilder(BuildContext _) => const CommunityScreen();
Widget _hunterHubBuilder(BuildContext _) => const HunterHubScreen();
Widget _moderationHubBuilder(BuildContext _) => const ModerationHubScreen();
Widget _miningBuilder(BuildContext _) => const MiningScreen();
Widget _walletBuilder(BuildContext _) => const WalletScreen();
Widget _profileBuilder(BuildContext _) =>
    const ProfileScreen(embeddedInMainShell: true);
