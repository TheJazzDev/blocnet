import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/app_icon_square.dart';
import 'package:blocnet/shared/widgets/app_surface.dart';
import 'package:flutter/material.dart';

/// The stat tile of the visual language: a tinted icon square beside a small
/// label and its value, in a flat card. Two per row. A chevron shows only
/// when the tile opens something.
///
/// Numbers use tabular figures so a value that ticks upward does not shuffle
/// its own digits sideways.
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

  /// Defaults to the live space accent.
  final Color? iconColor;
  final VoidCallback? onTap;

  /// Display-sized value, for the one stat a screen leads with.
  final bool large;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      onTap: onTap,
      padding: AppSpace.allMd,
      child: Row(
        children: [
          if (icon != null) ...[
            AppIconSquare(icon: icon, color: iconColor),
            AppSpace.wGapSm,
          ],
          Expanded(child: _texts()),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: AppIcon.sm,
              color: AppColors.textFaint,
            ),
        ],
      ),
    );
  }

  Widget _texts() {
    final valueStyle = large
        ? AppText.display(AppColors.textPrimary)
        : AppText.subtitle(AppColors.textPrimary, weight: AppText.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppText.caption(AppColors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          value,
          style: valueStyle.merge(AppText.tabular),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (delta != null) ...[
          AppSpace.gapHair,
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
    );
  }
}
