import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/app_icon_square.dart';
import 'package:flutter/material.dart';

/// The drawing behind `AppPill.caps`. Use `AppPill.caps` in feature code.
class AppCapsPill extends StatelessWidget {
  const AppCapsPill({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.dense = false,
    this.uppercase = true,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool dense;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final tone = color;
    final foreground = tone ?? AppColors.textMuted;
    final decoration = tone == null
        ? BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: AppRadius.full,
            border: Border.all(color: AppColors.borderMuted),
          )
        : appTintDecoration(tone, radius: AppRadius.full, bordered: true);
    final base = AppText.caption(foreground, weight: AppText.bold);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : AppSpace.sm,
        vertical: dense ? 1 : 3,
      ),
      decoration: decoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIcon.xs, color: foreground),
            AppSpace.wGapXs,
          ],
          Flexible(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: uppercase ? base.copyWith(letterSpacing: 0.6) : base,
            ),
          ),
        ],
      ),
    );
  }
}
