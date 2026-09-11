import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Shown on the Edge Engine page when the brief has no signals yet. Gives the
/// user the one thing that changes that: following projects.
class EdgeEmptyState extends StatelessWidget {
  const EdgeEmptyState({super.key, required this.onFollowProjects});

  final VoidCallback? onFollowProjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.radar_rounded,
                size: 18,
                color: AppColors.primary400,
              ),
              const SizedBox(width: 8),
              Text(
                'No signals yet',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Edge scores the updates from projects you follow. Follow a few '
            'projects and decisions will start showing up here.',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 12,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          if (onFollowProjects != null) ...[
            const SizedBox(height: 12),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text('Follow projects'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
