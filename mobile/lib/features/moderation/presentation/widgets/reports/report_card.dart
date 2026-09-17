import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_parts.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_styles.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

Color reportStatusColor(CommunityReportStatus status) => switch (status) {
      CommunityReportStatus.open => ModTone.open,
      CommunityReportStatus.resolved => ModTone.done,
      CommunityReportStatus.dismissed => ModTone.neutral,
    };

/// One report: status and target pills with the age, the reason, who and
/// what, the reporter's note, and the actions two to a row.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    required this.reviewing,
    required this.onResolve,
    required this.onDismiss,
    required this.onContentActions,
    required this.onUserActions,
  });

  final CommunityModerationReport report;
  final bool reviewing;
  final VoidCallback? onResolve;
  final VoidCallback? onDismiss;
  final VoidCallback? onContentActions;

  /// Null when the report names no member.
  final VoidCallback? onUserActions;

  @override
  Widget build(BuildContext context) {
    final target = report.targetUser?.bestLabel ?? report.targetUserId;
    final details = report.details?.trim() ?? '';
    final lock = reviewing;
    final actions = <Widget>[
      if (onResolve != null)
        AppButton(
          label: 'Resolve',
          icon: Icons.check_rounded,
          variant: AppButtonVariant.tinted,
          color: ModTone.done,
          onPressed: lock ? null : onResolve,
          size: AppButtonSize.compact,
        ),
      if (onDismiss != null)
        AppButton(
          label: 'Dismiss',
          icon: Icons.close_rounded,
          onPressed: lock ? null : onDismiss,
          variant: AppButtonVariant.outline,
          size: AppButtonSize.compact,
        ),
      if (onContentActions != null)
        AppButton(
          label: 'Content',
          icon: Icons.visibility_outlined,
          onPressed: lock ? null : onContentActions,
          variant: AppButtonVariant.outline,
          size: AppButtonSize.compact,
        ),
      if (onUserActions != null)
        AppButton(
          label: 'Member',
          icon: Icons.person_outline_rounded,
          color: ModTone.accent,
          onPressed: lock ? null : onUserActions,
          size: AppButtonSize.compact,
        ),
    ];

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ModPill(
                label: report.status.label,
                color: reportStatusColor(report.status),
              ),
              AppSpace.wGapXs,
              ModPill(
                label: report.targetType.label,
                color: AppColors.textMuted,
              ),
              const Spacer(),
              Text(
                getTimeStamp(report.createdAt),
                style: ModText.meta(AppColors.textFaint),
              ),
            ],
          ),
          AppSpace.gapMd,
          Text(
            report.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ModText.rowTitle(AppColors.textPrimary),
          ),
          AppSpace.gapXs,
          Text(
            [
              if (target != null) 'About $target',
              'by ${report.reporter.bestLabel}',
            ].join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ModText.meta(AppColors.textMuted),
          ),
          if (details.isNotEmpty) ...[
            AppSpace.gapSm,
            Text(
              details,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: ModText.body(AppColors.textSecondary),
            ),
          ],
          if (actions.isNotEmpty) ...[
            AppSpace.gapLg,
            _ActionGrid(actions: actions),
          ],
        ],
      ),
    );
  }
}

/// Two buttons per row; a lone last button takes the full width.
class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < actions.length; i += 2) {
      if (i > 0) rows.add(AppSpace.gapSm);
      rows.add(
        Row(
          children: [
            Expanded(child: actions[i]),
            if (i + 1 < actions.length) ...[
              AppSpace.wGapSm,
              Expanded(child: actions[i + 1]),
            ],
          ],
        ),
      );
    }
    return Column(children: rows);
  }
}
