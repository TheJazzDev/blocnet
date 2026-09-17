import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// A list row: tinted icon square, bold title, muted subtitle, optional
/// trailing widget and a chevron when the row opens something.
class ProfileListRow extends StatelessWidget {
  const ProfileListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.trailing,
    this.trailingIcon = Icons.chevron_right_rounded,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Replaces [subtitle] when the second line needs more than text.
  final Widget? subtitleWidget;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;

  /// Shown only when [onTap] is set.
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? AppColors.primary400;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(icon, size: AppIcon.sm, color: tint),
          ),
          AppSpace.wGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    titleColor ?? AppColors.textPrimary,
                    weight: AppText.semibold,
                  ),
                ),
                if (subtitleWidget != null) ...[
                  AppSpace.gapHair,
                  subtitleWidget!,
                ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                  AppSpace.gapHair,
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                      AppColors.textMuted,
                      weight: AppText.regular,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[AppSpace.wGapSm, trailing!],
          if (onTap != null) ...[
            AppSpace.wGapXs,
            Icon(trailingIcon, size: AppIcon.md, color: AppColors.textFaint),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
