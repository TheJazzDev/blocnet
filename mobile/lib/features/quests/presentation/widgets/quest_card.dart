import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_chips.dart';
import 'package:blocnet/features/quests/data/models/quest_models.dart';
import 'package:blocnet/features/quests/presentation/widgets/quest_pills.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// One quest in the Quests list: a flat card with a tinted type icon, the
/// title and reward, two lines of description, pills and a chevron.
class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.quest,
    required this.status,
    this.completedAt,
    this.onTap,
  });

  final QuestModel quest;
  final QuestStatus status;
  final DateTime? completedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = status.tone;
    return AppSurface(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(quest.type.iconData, size: AppIcon.md, color: tone),
          ),
          AppSpace.wGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        quest.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          AppColors.textPrimary,
                          weight: AppText.bold,
                        ).copyWith(height: 1.35),
                      ),
                    ),
                    AppSpace.wGapSm,
                    // Caps the pill so a very large reward shrinks rather
                    // than pushing the title off the card.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topRight,
                        child: QuestPointsPill(points: quest.rewardPoints),
                      ),
                    ),
                  ],
                ),
                if (quest.description.isNotEmpty) ...[
                  AppSpace.gapXs,
                  Text(
                    quest.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(AppColors.textMuted,
                        weight: AppText.regular),
                  ),
                ],
                AppSpace.gapSm,
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppSpace.xs,
                        runSpacing: AppSpace.xs,
                        children: [
                          BadgeCategoryChip(
                            category: quest.category,
                            compact: true,
                          ),
                          if (status != QuestStatus.notStarted)
                            QuestStatusPill(status: status),
                        ],
                      ),
                    ),
                    AppSpace.wGapSm,
                    if (completedAt != null)
                      Text(
                        formatQuestAge(completedAt!),
                        style: AppText.caption(AppColors.textFaint),
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        size: AppIcon.md,
                        color: AppColors.textFaint,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
