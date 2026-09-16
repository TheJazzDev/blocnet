import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// A tappable row linking from the Mine tab to one of its sub-screens.
class MiningSectionEntryCard extends StatelessWidget {
  const MiningSectionEntryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary400,
              size: AppIcon.md,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.labelSize,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: AppText.captionSize,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textFaint,
              size: AppIcon.md,
            ),
          ],
        ),
      ),
    );
  }
}
