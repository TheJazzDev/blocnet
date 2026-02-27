import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/engagement/data/models/radar_summary_model.dart';
import 'package:blocnet/services/auth_store.dart';
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading alpha radar...',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    final summary = radar;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    final subtitle = summary.hasUpdates
        ? '${summary.newUpdatesCount} new updates · ${summary.highUrgencyCount} high urgency'
        : 'You are fully caught up';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                'ALPHA RADAR',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10,
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
                      size: 12,
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
              size: 14,
              weight: FontWeight.w500,
            ),
          ),
          if (summary.activeProjects.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.activeProjects.take(3).map((project) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    '${project.projectName} · ${project.newCount}',
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 10,
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
