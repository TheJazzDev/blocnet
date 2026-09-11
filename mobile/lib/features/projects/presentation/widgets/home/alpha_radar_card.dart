import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_skeletons.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlphaRadarCard extends StatelessWidget {
  const AlphaRadarCard({
    super.key,
    required this.radar,
    required this.isLoading,
    required this.onCatchUp,
  });

  final RadarSummary? radar;
  final bool isLoading;
  final VoidCallback onCatchUp;

  @override
  Widget build(BuildContext context) {
    final accent =
        AppColors.accentForSpace(context.watch<AuthStore>().isInHunterSpace);
    if (isLoading) {
      return const RadarCardSkeleton();
    }

    final summary = radar;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    final subtitle = summary.hasUpdates
        ? '${summary.newUpdatesCount} new updates · ${summary.highUrgencyCount} high urgency'
        : 'You are fully caught up';

    return AppSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_rounded, size: AppIcon.sm, color: accent),
              const SizedBox(width: AppSpace.sm),
              Text(
                'ALPHA RADAR',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: AppText.captionSize,
                  weight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (summary.hasUpdates)
                TextButton(
                  onPressed: onCatchUp,
                  child: Text(
                    'Catch up now',
                    style: AppTypography.custom(
                      color: accent,
                      size: AppText.labelSize,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            subtitle,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.bodySize,
              weight: FontWeight.w500,
            ),
          ),
          if (summary.activeProjects.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.activeProjects.take(3).map((project) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm, vertical: AppSpace.xs),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(AppRadius.fullValue),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    '${project.projectName} · ${project.newCount}',
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: AppText.captionSize,
                      weight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
