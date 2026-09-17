part of '../main_screen.dart';

const _userTabs = [
  _TabMeta(
    title: 'Home',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Gems',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Community',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Mine',
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
    title: 'Gems',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Hub',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Mine',
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
    title: 'Gems',
    showSearch: true,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Moderation',
    showSearch: false,
    showFilter: false,
    showNotificationBell: true,
  ),
  _TabMeta(
    title: 'Mine',
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
    // Home and Gems only: the Community tab owns its own FAB.
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
        actions: _mineActions(currentIndex),
      ),
      body: LazyTabStack(
        index: currentIndex,
        builders: const [
          _homeBuilder,
          _gemsBuilder,
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
        actions:
            isHub ? const [HubHistoryAction()] : _mineActions(currentIndex),
      ),
      body: LazyTabStack(
        index: currentIndex,
        builders: const [
          _homeBuilder,
          _gemsBuilder,
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
        actions: _mineActions(currentIndex),
      ),
      body: LazyTabStack(
        index: currentIndex,
        builders: const [
          _homeBuilder,
          _gemsBuilder,
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

/// The Mine tab's history and help icons, in every space.
List<Widget> _mineActions(int index) =>
    index == MainTabScope.miningTab ? const [MineHeaderActions()] : const [];

Widget _homeBuilder(BuildContext _) => const HomeScreen();
Widget _gemsBuilder(BuildContext _) => const GemsScreen();
Widget _communityBuilder(BuildContext _) => const CommunityScreen();
Widget _hunterHubBuilder(BuildContext _) => const HunterHubScreen();
Widget _moderationHubBuilder(BuildContext _) => const ModerationHubScreen();
Widget _miningBuilder(BuildContext _) => const MiningScreen();
Widget _walletBuilder(BuildContext _) => const WalletScreen();
Widget _profileBuilder(BuildContext _) =>
    const ProfileScreen(embeddedInMainShell: true);
