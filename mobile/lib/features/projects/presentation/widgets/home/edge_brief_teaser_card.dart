import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/engagement/data/models/edge_brief_model.dart';
import 'package:flutter/material.dart';

class EdgeBriefTeaserCard extends StatelessWidget {
  const EdgeBriefTeaserCard({
    super.key,
    required this.brief,
    required this.isLoading,
    required this.onOpen,
  });

  final EdgeBriefResponse? brief;
  final bool isLoading;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.primary400,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading edge intelligence...',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final summary = brief;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary400,
              ),
              const SizedBox(width: 8),
              Text(
                'BLOCNET EDGE ENGINE',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10,
                  weight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpen,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: Text(
                  'Open',
                  style: AppTypography.custom(
                    color: AppColors.primary400,
                    size: 12,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            summary.headline.trim().isEmpty
                ? 'Edge intelligence is ready.'
                : summary.headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 13,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.totalSignals} signals · ${summary.recommendedNowCount} act now · ${summary.watchCount} watch',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 11,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
