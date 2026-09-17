import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/domain/level_requirement.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_status_chip.dart';
import 'package:flutter/material.dart';

/// Label and icon for each [LevelMetric], shared by the detail sheet and
/// the progress card.
extension LevelMetricPresentation on LevelMetric {
  String get label => switch (this) {
        LevelMetric.bnp => 'BNP earned',
        LevelMetric.comments => 'Comments on updates',
        LevelMetric.daysActive => 'Days active',
        LevelMetric.quests => 'Quests completed',
        LevelMetric.updates => 'Updates published',
        LevelMetric.projects => 'Projects created',
      };

  String get shortLabel => switch (this) {
        LevelMetric.bnp => 'BNP',
        LevelMetric.comments => 'Comments',
        LevelMetric.daysActive => 'Days active',
        LevelMetric.quests => 'Quests',
        LevelMetric.updates => 'Updates',
        LevelMetric.projects => 'Projects',
      };

  IconData get icon => switch (this) {
        LevelMetric.bnp => Icons.stars_rounded,
        LevelMetric.comments => Icons.chat_bubble_outline_rounded,
        LevelMetric.daysActive => Icons.calendar_today_outlined,
        LevelMetric.quests => Icons.flag_outlined,
        LevelMetric.updates => Icons.article_outlined,
        LevelMetric.projects => Icons.folder_outlined,
      };
}

/// One criterion as a list row: tinted icon square, label, current vs
/// required, a thin bar and, when unmet, how much is left. Rows sit in one
/// card separated by hairlines.
class LevelRequirementRow extends StatelessWidget {
  const LevelRequirementRow({
    super.key,
    required this.requirement,
    required this.tierColor,
  });

  final LevelRequirement requirement;
  final Color tierColor;

  @override
  Widget build(BuildContext context) {
    final complete = requirement.isComplete;
    final metric = requirement.metric;
    final tone = complete ? AppColors.successColor : AppColors.textMuted;

    return Padding(
      padding: AppSpace.row,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(
              complete ? Icons.check_rounded : metric.icon,
              size: AppIcon.sm,
              color: tone,
            ),
          ),
          AppSpace.wGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        metric.label,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(
                          AppColors.textPrimary,
                          weight: AppText.bold,
                        ),
                      ),
                    ),
                    AppSpace.wGapSm,
                    Text(
                      '${requirement.currentLabel} / ${requirement.requiredLabel}',
                      style: AppText.caption(
                        complete ? AppColors.successColor : AppColors.textMuted,
                        weight: AppText.semibold,
                      ).merge(AppText.tabular),
                    ),
                  ],
                ),
                AppSpace.gapXs,
                LinearProgressIndicator(
                  value: requirement.ratio,
                  minHeight: 4,
                  borderRadius: AppRadius.full,
                  backgroundColor: AppColors.bgElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                ),
              ],
            ),
          ),
          if (!complete) ...[
            AppSpace.wGapSm,
            LevelStatusChip(
              label: '+${requirement.remainingLabel}',
              color: AppColors.textMuted,
              filled: false,
            ),
          ],
        ],
      ),
    );
  }
}
