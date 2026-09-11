import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.mdValue),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: AppText.subtitleSize,
                weight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.captionSize,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
