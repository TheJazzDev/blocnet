import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

class EmptyFeed extends StatelessWidget {
  const EmptyFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      margin: const EdgeInsets.fromLTRB(0, AppSpace.lg, 0, 0),
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        children: [
          Icon(
            Icons.article_outlined,
            size: AppIcon.xl,
            color: AppColors.textFaint,
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'No updates yet',
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: AppText.bodySize,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Hunter intel will appear here when updates are posted.',
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
