import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:flutter/material.dart';

/// Small uppercase pill (`CURRENT`, `LOCKED`, `DONE`) tinted with a tier
/// colour. [filled] paints a solid background; otherwise a soft tint.
class LevelStatusChip extends StatelessWidget {
  const LevelStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.filled = true,
    this.icon,
  });

  final String label;
  final Color color;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? foregroundOn(color) : color;

    return Container(
      // xs, not sm: this is the smallest component in the system and it sits
      // inside a grid tile. sm padding overflows the tile once the label is
      // at caption size.
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xs,
        vertical: AppSpace.hair,
      ),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIcon.xs, color: foreground),
            const SizedBox(width: AppSpace.hair),
          ],
          Text(
            label,
            style: AppTypography.custom(
              color: foreground,
              size: AppText.captionSize,
              weight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
