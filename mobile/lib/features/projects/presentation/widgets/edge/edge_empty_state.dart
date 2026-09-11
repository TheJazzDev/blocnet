import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Shown on the Edge Engine page when the brief has no signals yet. Gives the
/// user the one thing that changes that: following gems.
class EdgeEmptyState extends StatelessWidget {
  const EdgeEmptyState({super.key, required this.onFollowProjects});

  final VoidCallback? onFollowProjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.radar_rounded,
                size: AppIcon.md,
                color: AppColors.primary400,
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                'No signals yet',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.bodySize,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Edge scores the updates from gems you follow. Follow a few '
            'gems and decisions will start showing up here.',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          if (onFollowProjects != null) ...[
            const SizedBox(height: AppSpace.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onFollowProjects,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(42),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.mdValue),
                  ),
                ),
                icon: const Icon(Icons.explore_rounded, size: AppIcon.md),
                label: const Text('Follow gems'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
