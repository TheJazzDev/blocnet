import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class EmptyActivityCard extends StatelessWidget {
  const EmptyActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        'No public posts available yet.',
        style: AppTypography.custom(
          color: AppColors.textMuted,
          size: AppText.bodySize,
          weight: FontWeight.w400,
        ),
      ),
    );
  }
}
