import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// One option of the Internal / External toggle on the token send page.
class SendModeTile extends StatelessWidget {
  const SendModeTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? AppColors.teal500.withValues(alpha: 0.55)
        : AppColors.borderSubtle;
    final bgColor = isActive
        ? AppColors.teal500.withValues(alpha: 0.1)
        : AppColors.bgSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.mdValue),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.mdValue),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: AppIcon.sm, color: AppColors.teal400),
            const SizedBox(width: AppSpace.sm),
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
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: AppText.captionSize,
                      weight: FontWeight.w400,
                    ),
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
