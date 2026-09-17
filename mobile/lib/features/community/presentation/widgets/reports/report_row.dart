import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/app_pill.dart';
import 'package:flutter/material.dart';

Color reportStatusColor(CommunityReportStatus status) => switch (status) {
      CommunityReportStatus.open => AppColors.warning500,
      CommunityReportStatus.resolved => AppColors.successColor,
      CommunityReportStatus.dismissed => AppColors.tagGeneral,
    };

/// One report the member sent: what, why, when, and what moderators did.
class ReportRow extends StatelessWidget {
  const ReportRow({super.key, required this.report});

  final CommunityModerationReport report;

  @override
  Widget build(BuildContext context) {
    final details = report.details?.trim() ?? '';
    final note = report.resolutionNote?.trim() ?? '';
    final reviewedAt = report.reviewedAt;

    return Container(
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
              AppPill(
                label: report.targetType.label,
                color: AppColors.tagGeneral,
                style: AppPillStyle.outlined,
                dense: true,
                uppercase: true,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'Sent ${getTimeStamp(report.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _caption,
                ),
              ),
              AppPill(
                label: report.status.label,
                color: reportStatusColor(report.status),
                dense: true,
                uppercase: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            report.reason,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.bodySize,
              weight: FontWeight.w700,
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              details,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.bodySize,
                weight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
          if (report.status != CommunityReportStatus.open) ...[
            const SizedBox(height: AppSpace.md),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: AppSpace.md),
            Text(
              reviewedAt == null
                  ? report.status.label
                  : '${report.status.label} ${getTimeStamp(reviewedAt)}',
              style: _caption,
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                note,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

final TextStyle _caption = AppTypography.custom(
  color: AppColors.textFaint,
  size: AppText.labelSize,
  weight: FontWeight.w500,
);
