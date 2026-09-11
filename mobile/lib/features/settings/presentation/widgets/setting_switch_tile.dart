import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// One settings row: icon, title, subtitle and a trailing switch.
///
/// [subtitleWidget] replaces the plain [subtitle] text when a row needs a
/// richer subtitle (e.g. a tappable "+ N more"). [footer] renders under the
/// row, above the divider, for expandable detail.
class SettingSwitchTile extends StatelessWidget {
  const SettingSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
    this.subtitleWidget,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;
  final Widget? subtitleWidget;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onChanged != null;
    final iconColor = value ? AppColors.teal400 : AppColors.textMuted;
    final subtitleColor = isEnabled
        ? AppColors.textMuted
        : AppColors.textMuted.withValues(alpha: 0.7);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
          child: Row(
            children: [
              Icon(icon, size: AppIcon.md, color: iconColor),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.custom(
                        color: isEnabled
                            ? AppColors.textPrimary
                            : AppColors.textPrimary.withValues(alpha: 0.7),
                        size: AppText.bodySize,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpace.hair),
                    subtitleWidget ??
                        Text(
                          subtitle,
                          style: AppTypography.custom(
                            color: subtitleColor,
                            size: AppText.labelSize,
                            weight: FontWeight.w500,
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.teal400,
                activeTrackColor: AppColors.teal500.withValues(alpha: 0.35),
                inactiveThumbColor: AppColors.textFaint,
                inactiveTrackColor: AppColors.bgElevated,
              ),
            ],
          ),
        ),
        if (footer != null) footer!,
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderSubtle,
          ),
      ],
    );
  }
}
