import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// The uppercase label that opens a section, with an optional action on the
/// right (`View All`, `Manage`, a count).
///
/// The app writes this by hand each time, which is why the letter-spacing,
/// the gap to the icon and the action's alignment drift between screens.
///
/// ```dart
/// AppSectionHeader(
///   title: 'Top Hunters',
///   icon: Icons.trending_up_rounded,
///   actionLabel: 'View All',
///   onAction: () => openLeaderboard(),
/// )
/// ```
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.padding,
    super.key,
  });

  /// Rendered uppercase. Pass it in sentence case.
  final String title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            AppSpace.sm,
          ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIcon.sm, color: AppColors.textFaint),
            const SizedBox(width: AppSpace.sm),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppText.caption(
                AppColors.textFaint,
                weight: AppText.semibold,
              ).copyWith(letterSpacing: 1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                // Keeps the tap target at the 44px accessibility minimum
                // without moving the label off the header's baseline.
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.sm,
                ),
                child: Text(
                  actionLabel!,
                  style: AppText.label(
                    AppColors.primary500,
                    weight: AppText.semibold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
