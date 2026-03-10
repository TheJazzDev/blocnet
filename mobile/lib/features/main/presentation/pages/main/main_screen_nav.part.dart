part of '../main_screen.dart';

class _UserNav extends StatelessWidget {
  const _UserNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.userAccent;
    return _NavContainer(
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.user,
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.user,
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.groups_outlined,
            activeIcon: Icons.groups_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.user,
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.bolt_outlined,
            activeIcon: Icons.bolt_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.user,
            isActive: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.user,
            isActive: currentIndex == 4,
            onTap: () => onTap(4),
          ),
          _NavItem(
            icon: Icons.person_outlined,
            activeIcon: Icons.person_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.user,
            isActive: currentIndex == 5,
            onTap: () => onTap(5),
          ),
        ],
      ),
    );
  }
}

class _HunterNav extends StatelessWidget {
  const _HunterNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.hunterAccent;
    return _NavContainer(
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.hunter,
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.hunter,
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.radar_outlined,
            activeIcon: Icons.radar_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.hunter,
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.bolt_outlined,
            activeIcon: Icons.bolt_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.hunter,
            isActive: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.hunter,
            isActive: currentIndex == 4,
            onTap: () => onTap(4),
          ),
          _NavItem(
            icon: Icons.person_outlined,
            activeIcon: Icons.person_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.hunter,
            isActive: currentIndex == 5,
            onTap: () => onTap(5),
          ),
        ],
      ),
    );
  }
}

class _ModerationNav extends StatelessWidget {
  const _ModerationNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.moderationAccent;
    return _NavContainer(
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.moderation,
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.moderation,
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.shield_outlined,
            activeIcon: Icons.shield_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.moderation,
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.bolt_outlined,
            activeIcon: Icons.bolt_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.moderation,
            isActive: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.moderation,
            isActive: currentIndex == 4,
            onTap: () => onTap(4),
          ),
          _NavItem(
            icon: Icons.person_outlined,
            activeIcon: Icons.person_rounded,
            activeColor: activeColor,
            navSpace: _NavSpace.moderation,
            isActive: currentIndex == 5,
            onTap: () => onTap(5),
          ),
        ],
      ),
    );
  }
}

class _FloatingComposerFab extends StatelessWidget {
  const _FloatingComposerFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary400, AppColors.primary600],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.bgBase,
            width: 3,
          ),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.black,
          size: 24,
        ),
      ),
    );
  }
}

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
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.activeColor,
    required this.navSpace,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final Color activeColor;
  final _NavSpace navSpace;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : AppColors.textMuted;
    final iconToRender = isActive ? activeIcon : icon;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedScale(
            scale: isActive ? 1.0 : 0.95,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Icon(
              iconToRender,
              size: isActive ? 26 : 24,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

enum _NavSpace {
  user,
  hunter,
  moderation,
}
