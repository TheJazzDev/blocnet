import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/presentation/widgets/reports/report_row.dart';
import 'package:blocnet/shared/widgets/app_pill.dart';
import 'package:flutter/material.dart';

/// A card header with the member's reports counted by status.
class ReportsSummary extends StatelessWidget {
  const ReportsSummary({super.key, required this.counts});

  final CommunityReportCounts counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpace.card,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: AppIcon.sm,
                color: AppColors.primary400,
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                'YOUR REPORTS · ${counts.total}',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: AppText.captionSize,
                  weight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              _count(counts.open, CommunityReportStatus.open),
              _count(counts.resolved, CommunityReportStatus.resolved),
              _count(counts.dismissed, CommunityReportStatus.dismissed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _count(int value, CommunityReportStatus status) => AppPill(
        label: '$value ${status.label.toLowerCase()}',
        color: reportStatusColor(status),
      );
}
