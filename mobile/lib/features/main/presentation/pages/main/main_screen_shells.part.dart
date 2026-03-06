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
    title: 'Hunter Hub',
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
    final auth = context.watch<AuthStore>();
    final showCommunityStaffToolsAction =
        currentIndex == 2 && auth.canAccessCommunityStaffTools;

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
        actions: [
          if (showCommunityStaffToolsAction)
            _MainShellActionIcon(
              icon: Icons.gavel_rounded,
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.communityStaffTools);
              },
            ),
        ],
      ),
      body: _LazyTabStack(
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
      bottomNavigationBar: _UserNav(
        currentIndex: currentIndex,
        onTap: onNavTap,
      ),
    );
  }
}

class _MainShellActionIcon extends StatelessWidget {
  const _MainShellActionIcon({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Center(
          child: Icon(
            icon,
            color: AppColors.textSecondary,
            size: 21,
          ),
        ),
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
        currentIndex == 0 || currentIndex == 1 || currentIndex == 2;

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
      body: _LazyTabStack(
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

Widget _homeBuilder(BuildContext _) => const HomeScreen();
Widget _discoverBuilder(BuildContext _) => const DiscoverScreen();
Widget _communityBuilder(BuildContext _) => const CommunityScreen();
Widget _hunterHubBuilder(BuildContext _) => const HunterHubScreen();
Widget _miningBuilder(BuildContext _) => const MiningScreen();
Widget _walletBuilder(BuildContext _) => const WalletScreen();
Widget _profileBuilder(BuildContext _) =>
    const ProfileScreen(embeddedInMainShell: true);

class _LazyTabStack extends StatefulWidget {
  const _LazyTabStack({
    required this.index,
    required this.builders,
  });

  final int index;
  final List<WidgetBuilder> builders;

  @override
  State<_LazyTabStack> createState() => _LazyTabStackState();
}

class _LazyTabStackState extends State<_LazyTabStack> {
  late final List<Widget?> _builtChildren =
      List<Widget?>.filled(widget.builders.length, null, growable: true);

  @override
  void didUpdateWidget(covariant _LazyTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.builders.length != widget.builders.length) {
      _builtChildren
        ..clear()
        ..addAll(List<Widget?>.filled(widget.builders.length, null));
    }
  }

  @override
  Widget build(BuildContext context) {
    _builtChildren[widget.index] ??= widget.builders[widget.index](context);

    return IndexedStack(
      index: widget.index,
      children: List<Widget>.generate(widget.builders.length, (index) {
        return _builtChildren[index] ?? const SizedBox.shrink();
      }),
    );
  }
}
