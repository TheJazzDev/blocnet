import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// One settings row: tinted icon square, title, subtitle and a switch.
///
/// [subtitleWidget] replaces the plain [subtitle] text when a row needs a
/// richer subtitle (e.g. a tappable "+ N more"). [footer] renders under the
/// row for expandable detail. Rows sit in an `AppRowGroup`, which draws
/// the hairlines.
class SettingSwitchTile extends StatelessWidget {
  const SettingSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.iconColor,
    this.subtitleWidget,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Defaults to the space accent.
  final Color? iconColor;
  final Widget? subtitleWidget;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final tint = iconColor ?? AppColors.primary400;
    final fade = enabled ? 1.0 : 0.55;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.md, AppSpace.sm, AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Opacity(
                opacity: fade,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: AppRadius.sm,
                  ),
                  child: Icon(icon, size: AppIcon.sm, color: tint),
                ),
              ),
              AppSpace.wGapMd,
              Expanded(
                child: Opacity(
                  opacity: fade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.body(AppColors.textPrimary,
                            weight: AppText.semibold),
                      ),
                      AppSpace.gapHair,
                      subtitleWidget ??
                          Text(
                            subtitle,
                            style: AppText.label(AppColors.textMuted,
                                weight: AppText.regular),
                          ),
                    ],
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary400,
                activeTrackColor: AppColors.primary500.withValues(alpha: 0.35),
                inactiveThumbColor: AppColors.textFaint,
                inactiveTrackColor: AppColors.bgElevated,
              ),
            ],
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}
