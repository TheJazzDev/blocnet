import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Underlined segmented tab bar for the Activity / Following / Saved tabs.
class ProfileTabBar extends StatelessWidget {
  const ProfileTabBar({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onChanged,
    required this.accent,
  });

  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.only(bottom: AppSpace.hair),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == activeIndex ? accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  height: 44,
                  child: Text(
                    tabs[i],
                    style: AppTypography.custom(
                      color: i == activeIndex ? accent : AppColors.textFaint,
                      size: AppText.bodySize,
                      weight:
                          i == activeIndex ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shared empty-state block for the three profile tabs.
class ProfileTabEmptyState extends StatelessWidget {
  const ProfileTabEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
  });

  final IconData icon;
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIcon.xl, color: AppColors.textFaint),
            const SizedBox(height: AppSpace.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.bodySize,
                weight: FontWeight.w400,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: AppText.captionSize,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Wraps a list tile so it renders as a card in card mode or a divided
/// row in list mode.
class ProfileTabTileFrame extends StatelessWidget {
  const ProfileTabTileFrame({
    super.key,
    required this.isCardMode,
    required this.showDivider,
    required this.child,
    this.onTap,
  });

  final bool isCardMode;
  final bool showDivider;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isCardMode ? 10 : 0),
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: isCardMode
            ? BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(AppRadius.mdValue),
                border: Border.all(color: AppColors.borderSubtle),
              )
            : null,
        child: child,
      ),
    );

    if (isCardMode) return tile;

    return Column(
      children: [
        tile,
        if (showDivider)
          Divider(
            height: 1,
            color: AppColors.borderSubtle.withValues(alpha: 0.8),
          ),
      ],
    );
  }
}
