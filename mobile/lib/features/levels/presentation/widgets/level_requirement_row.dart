import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
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

/// One criterion row in the level detail sheet: icon, label, current vs
/// required and a thin progress bar, all tinted with the tier colour.
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: complete ? tierColor.withValues(alpha: 0.08) : AppColors.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: complete
              ? tierColor.withValues(alpha: 0.35)
              : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: complete
                  ? tierColor.withValues(alpha: 0.16)
                  : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              complete ? Icons.check_rounded : metric.icon,
              size: 16,
              color: complete ? tierColor : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        metric.label,
                        style: AppTypography.custom(
                          color: AppColors.textPrimary,
                          size: 12,
                          weight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${requirement.currentLabel} / ${requirement.requiredLabel}',
                      style: AppTypography.custom(
                        color: complete ? tierColor : AppColors.textMuted,
                        size: 11,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: requirement.ratio,
                    minHeight: 4,
                    backgroundColor: AppColors.borderSubtle,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      complete ? tierColor : tierColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!complete) ...[
            const SizedBox(width: 8),
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
