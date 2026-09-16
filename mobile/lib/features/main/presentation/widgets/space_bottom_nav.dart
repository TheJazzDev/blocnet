import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The three spaces that share the bottom bar. Only slot 3 differs.
enum NavSpace { user, hunter, moderation }

@immutable
class NavTabSpec {
  const NavTabSpec(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Home · Gems · Community|Hub|Moderate · Mine · Wallet · Profile, labelled,
/// with the active tab in the space accent (design: Hunter Hub `.tabs`).
class SpaceBottomNav extends StatelessWidget {
  const SpaceBottomNav({
    super.key,
    required this.space,
    required this.currentIndex,
    required this.onTap,
  });

  final NavSpace space;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const NavTabSpec _home =
      NavTabSpec('Home', Icons.home_outlined, Icons.home_rounded);
  static const NavTabSpec _gems =
      NavTabSpec('Gems', Icons.diamond_outlined, Icons.diamond_rounded);
  static const NavTabSpec _mine =
      NavTabSpec('Mine', Icons.bolt_outlined, Icons.bolt_rounded);
  static const NavTabSpec _wallet = NavTabSpec(
    'Wallet',
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet_rounded,
  );
  static const NavTabSpec _profile =
      NavTabSpec('Profile', Icons.person_outline_rounded, Icons.person_rounded);

  static List<NavTabSpec> tabsFor(NavSpace space) {
    final third = switch (space) {
      NavSpace.user => const NavTabSpec(
          'Community', Icons.groups_outlined, Icons.groups_rounded),
      NavSpace.hunter =>
        const NavTabSpec('Hub', Icons.shield_outlined, Icons.shield_rounded),
      NavSpace.moderation =>
        const NavTabSpec('Moderate', Icons.gavel_outlined, Icons.gavel_rounded),
    };
    return [_home, _gems, third, _mine, _wallet, _profile];
  }

  static Color accentFor(NavSpace space) => switch (space) {
        NavSpace.user => AppColors.userAccent,
        NavSpace.hunter => AppColors.hunterAccent,
        NavSpace.moderation => AppColors.moderationAccent,
      };

  @override
  Widget build(BuildContext context) {
    final tabs = tabsFor(space);
    final accent = accentFor(space);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.navGround,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavTab(
                    spec: tabs[i],
                    active: i == currentIndex,
                    accent: accent,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.spec,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final NavTabSpec spec;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? accent : AppColors.zincDim;
    void select() {
      HapticFeedback.selectionClick();
      onTap();
    }

    // One node per tab, named by its visible word, so accessibility tools
    // and uiautomator (content-desc) see "Hub" rather than an empty button.
    // The tap is exposed on that node because the gesture below is excluded.
    return Semantics(
      button: true,
      selected: active,
      label: spec.label,
      onTap: select,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: select,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? spec.activeIcon : spec.icon,
                  size: 20, color: color),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  spec.label,
                  maxLines: 1,
                  style: AppTypography.custom(
                    size: 11,
                    weight: FontWeight.w500,
                    color: color,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
