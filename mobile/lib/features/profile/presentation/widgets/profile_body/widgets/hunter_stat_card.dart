import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// One of the two headline hunter numbers: an icon, a label, the value and a
/// one-line footnote saying what the value was computed from.
class HunterStatCard extends StatelessWidget {
  const HunterStatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.footnote,
    this.valueSize = AppText.subtitleSize,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String footnote;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md, vertical: AppSpace.sm),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgSurface,
              AppColors.bgSurface.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: AppRadius.md,
          border: Border.all(color: iconColor.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.06),
              blurRadius: AppSpace.md,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: AppIcon.xl,
              height: AppIcon.xl,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.2),
                    iconColor.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: iconColor, size: AppIcon.sm),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppText.caption(
                      AppColors.textFaint,
                      weight: AppText.bold,
                    ).copyWith(letterSpacing: 0.55),
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Text(
                    value,
                    style: AppText.subtitle(iconColor, weight: AppText.bold)
                        .copyWith(fontSize: valueSize),
                  ),
                  Text(
                    footnote,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption(AppColors.textFaint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
