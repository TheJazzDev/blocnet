import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/engagement/data/models/edge_brief_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_skeletons.dart';
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
      return const EdgeBriefSkeleton();
    }

    final summary = brief;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: AppIcon.sm,
                color: AppColors.primary400,
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                'BLOCNET EDGE ENGINE',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: AppText.captionSize,
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
                      const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
                ),
                child: Text(
                  'Open',
                  style: AppTypography.custom(
                    color: AppColors.primary400,
                    size: AppText.labelSize,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            summary.headline.trim().isEmpty
                ? 'Edge intelligence is ready.'
                : summary.headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.labelSize,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            '${summary.totalSignals} signals · ${summary.recommendedNowCount} act now · ${summary.watchCount} watch',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.captionSize,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
