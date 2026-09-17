import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_button.dart';
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
        ModButton(
          label: 'Resolve',
          icon: Icons.check_rounded,
          tone: ModButtonTone.tinted,
          color: ModTone.done,
          onTap: lock ? null : onResolve,
        ),
      if (onDismiss != null)
        ModButton(
          label: 'Dismiss',
          icon: Icons.close_rounded,
          onTap: lock ? null : onDismiss,
        ),
      if (onContentActions != null)
        ModButton(
          label: 'Content',
          icon: Icons.visibility_outlined,
          onTap: lock ? null : onContentActions,
        ),
      if (onUserActions != null)
        ModButton(
          label: 'Member',
          icon: Icons.person_outline_rounded,
          tone: ModButtonTone.filled,
          onTap: lock ? null : onUserActions,
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
