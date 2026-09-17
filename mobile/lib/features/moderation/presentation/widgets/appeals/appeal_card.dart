import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/moderation/data/models/community_appeal_model.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_parts.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_styles.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Color appealStatusColor(CommunityAppealStatus status) => switch (status) {
      CommunityAppealStatus.pending => ModTone.open,
      CommunityAppealStatus.underReview => ModTone.review,
      CommunityAppealStatus.approved => ModTone.done,
      CommunityAppealStatus.rejected => ModTone.accent,
    };

/// One appeal: status pill and date, who appealed and why, the original
/// report, the review if there is one, and Overturn / Uphold while open.
class AppealCard extends StatelessWidget {
  const AppealCard({
    super.key,
    required this.appeal,
    required this.onOverturn,
    required this.onUphold,
    this.busy = false,
  });

  final CommunityAppeal appeal;
  final VoidCallback onOverturn;
  final VoidCallback onUphold;
  final bool busy;

  bool get _isOpen =>
      appeal.status == CommunityAppealStatus.pending ||
      appeal.status == CommunityAppealStatus.underReview;

  @override
  Widget build(BuildContext context) {
    final report = appeal.report;
    final reviewer = appeal.reviewedBy;
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppPill.caps(
                label: appeal.statusLabel,
                color: appealStatusColor(appeal.status),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, HH:mm').format(appeal.createdAt.toLocal()),
                style: ModText.meta(AppColors.textFaint),
              ),
            ],
          ),
          AppSpace.gapMd,
          Text(
            appeal.appealer?.name ?? 'Unknown member',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ModText.rowTitle(AppColors.textPrimary),
          ),
          AppSpace.gapXs,
          Text(
            appeal.reason,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: ModText.body(AppColors.textSecondary),
          ),
          if (report != null)
            _Section(
              label: 'Original report',
              lines: [
                report.category,
                if ((report.reviewNotes ?? '').trim().isNotEmpty)
                  report.reviewNotes!.trim(),
              ],
            ),
          if (reviewer != null)
            _Section(
              label: 'Review',
              lines: [
                [
                  appeal.decisionLabel ?? appeal.statusLabel,
                  'by ${reviewer.name}',
                ].join(' '),
                if ((appeal.reviewNotes ?? '').trim().isNotEmpty)
                  appeal.reviewNotes!.trim(),
              ],
            ),
          if (_isOpen) ...[
            AppSpace.gapLg,
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Overturn',
                    variant: AppButtonVariant.tinted,
                    color: ModTone.done,
                    onPressed: busy ? null : onOverturn,
                    size: AppButtonSize.compact,
                  ),
                ),
                AppSpace.wGapSm,
                Expanded(
                  child: AppButton(
                    label: 'Uphold',
                    variant: AppButtonVariant.tinted,
                    color: ModTone.accent,
                    onPressed: busy ? null : onUphold,
                    size: AppButtonSize.compact,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A hairline, a caps label, then plain lines.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.lines});

  final String label;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHairline(),
          AppSpace.gapMd,
          Text(label.toUpperCase(), style: ModText.caps(AppColors.textFaint)),
          for (final line in lines) ...[
            AppSpace.gapXs,
            Text(
              line,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: ModText.meta(AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
