import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Outlined status pill: faint tint, coloured hairline, coloured 10px caps.
class ProfilePill extends StatelessWidget {
  const ProfilePill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIcon.xs, color: color),
            AppSpace.wGapXs,
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption(color, weight: AppText.bold)
                  .copyWith(letterSpacing: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
