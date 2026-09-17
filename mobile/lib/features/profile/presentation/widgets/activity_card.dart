import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// One activity row: title, a muted second line and the time. Meant to sit
/// in a `ProfileRowGroup`.
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData? icon;

  /// When null the row is plain text: no ripple and no chevron.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIcon.sm, color: AppColors.primary400),
            AppSpace.wGapMd,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    AppColors.textPrimary,
                    weight: AppText.semibold,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  AppSpace.gapHair,
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(AppColors.textMuted,
                        weight: AppText.regular),
                  ),
                ],
              ],
            ),
          ),
          AppSpace.wGapSm,
          Text(time, style: AppText.label(AppColors.textFaint)),
          if (onTap != null) ...[
            AppSpace.wGapXs,
            Icon(
              Icons.chevron_right_rounded,
              size: AppIcon.sm,
              color: AppColors.textFaint,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}
