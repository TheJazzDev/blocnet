import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Flat card: surface ground, 1px subtle edge, [AppRadius.md].
BoxDecoration alertCardDecoration() => BoxDecoration(
      color: AppColors.bgSurface,
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.borderSubtle),
    );

/// 10px bold caps in [color].
TextStyle alertCaps(Color color) =>
    AppText.caption(color, weight: AppText.bold).copyWith(letterSpacing: 1.0);

/// Outlined status pill: faint tint, coloured hairline, caps text.
class AlertPill extends StatelessWidget {
  const AlertPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: alertCaps(color).copyWith(letterSpacing: 0.6),
      ),
    );
  }
}

/// Tinted icon square at the head of a row.
class AlertIconSquare extends StatelessWidget {
  const AlertIconSquare({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, size: AppIcon.sm, color: color),
    );
  }
}

/// A left-aligned card with an icon, a title, a line and an optional action.
class AlertMessageCard extends StatelessWidget {
  const AlertMessageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpace.card,
      decoration: alertCardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlertIconSquare(icon: icon, color: AppColors.textFaint),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body(AppColors.textPrimary,
                      weight: AppText.bold),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(message, style: AppText.label(AppColors.textMuted)),
                if (action != null) ...[
                  const SizedBox(height: AppSpace.md),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
