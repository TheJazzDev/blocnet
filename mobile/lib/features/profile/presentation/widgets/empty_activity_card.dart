import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class EmptyActivityCard extends StatelessWidget {
  const EmptyActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        'No public posts available yet.',
        style: AppTypography.custom(
          color: AppColors.textMuted,
          size: 12,
          weight: FontWeight.w400,
        ),
      ),
    );
  }
}
