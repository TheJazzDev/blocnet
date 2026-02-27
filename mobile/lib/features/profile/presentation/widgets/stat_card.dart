import 'package:blocnet/app/theme.dart';
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 17,
                weight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 11,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
