import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/app_surface.dart';
import 'package:flutter/material.dart';

/// Label over a number, with an optional icon and a delta line.
///
/// The mining dashboard, hunter stats, wallet and the profile header all draw
/// this and all draw it differently. Numbers use tabular figures here so a
/// value that ticks upward does not shuffle its own digits sideways.
///
/// ```dart
/// AppStatTile(label: 'Active miners', value: '12,480', delta: '+8.2%')
/// AppStatTile(label: 'Total Earned', value: '0 BNP', icon: Icons.star_rounded)
/// ```
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    required this.label,
    required this.value,
    this.delta,
    this.deltaIsPositive = true,
    this.icon,
    this.iconColor,
    this.onTap,
    this.large = false,
    super.key,
  });

  final String label;
  final String value;

  /// A change line beneath the value, e.g. `+8.2% vs. yesterday`.
  final String? delta;
  final bool deltaIsPositive;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  /// Display-sized value, for the one stat a screen leads with.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? AppColors.primary500;

    return AppSurface(
      onTap: onTap,
      padding: AppSpace.allMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: AppSpace.allXs,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: AppRadius.sm,
                  ),
                  child: Icon(icon, size: AppIcon.sm, color: tint),
                ),
                const SizedBox(width: AppSpace.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppText.caption(AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            value,
            style: (large
                    ? AppText.display(AppColors.textPrimary)
                    : AppText.subtitle(AppColors.textPrimary))
                .merge(AppText.tabular),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (delta != null) ...[
            const SizedBox(height: AppSpace.hair),
            Text(
              delta!,
              style: AppText.caption(
                deltaIsPositive ? AppColors.successColor : AppColors.error500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
