import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_chips.dart';
import 'package:blocnet/features/quests/data/models/quest_models.dart';
import 'package:blocnet/features/quests/presentation/widgets/quest_pills.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// A flat card with a small caps header, used by every quest detail block.
class QuestSectionCard extends StatelessWidget {
  const QuestSectionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: label,
            icon: icon,
            padding: const EdgeInsets.only(bottom: AppSpace.md),
          ),
          child,
        ],
      ),
    );
  }
}

/// Type icon, title and pills, left-aligned.
class QuestDetailHeader extends StatelessWidget {
  const QuestDetailHeader({
    super.key,
    required this.quest,
    required this.status,
  });

  final QuestModel quest;
  final QuestStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = status.tone;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            borderRadius: AppRadius.md,
          ),
          child: Icon(quest.type.iconData, size: AppIcon.lg, color: tone),
        ),
        AppSpace.wGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quest.title, style: AppText.title(AppColors.textPrimary)),
              AppSpace.gapSm,
              Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: [
                  BadgeCategoryChip(category: quest.category, compact: true),
                  QuestTypePill(type: quest.type),
                  if (status != QuestStatus.notStarted)
                    QuestStatusPill(status: status),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Description, required proof and how the quest is checked.
class QuestAboutSection extends StatelessWidget {
  const QuestAboutSection({super.key, required this.quest});

  final QuestModel quest;

  @override
  Widget build(BuildContext context) {
    final proof = quest.requiredProof?.trim();
    return QuestSectionCard(
      icon: Icons.info_outline_rounded,
      label: 'About',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quest.description.isNotEmpty)
            Text(
              quest.description,
              style: AppText.body(AppColors.textSecondary),
            ),
          if (proof != null && proof.isNotEmpty) ...[
            AppSpace.gapMd,
            Text(
              'Proof needed',
              style: AppText.label(AppColors.textPrimary, weight: AppText.bold),
            ),
            AppSpace.gapXs,
            Text(proof, style: AppText.body(AppColors.textSecondary)),
          ],
          AppSpace.gapMd,
          Row(
            children: [
              Icon(
                quest.isAutoVerified
                    ? Icons.verified_outlined
                    : Icons.fact_check_outlined,
                size: AppIcon.sm,
                color: AppColors.textFaint,
              ),
              AppSpace.wGapSm,
              Text(
                quest.isAutoVerified
                    ? 'Checked automatically'
                    : 'Checked by a moderator',
                style: AppText.label(AppColors.textFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The reward as stat tiles: BNP, and the badge when the quest grants one.
class QuestRewardSection extends StatelessWidget {
  const QuestRewardSection({super.key, required this.quest});

  final QuestModel quest;

  @override
  Widget build(BuildContext context) {
    final points = AppStatTile(
      label: 'Reward',
      value: '${quest.rewardPoints} BNP',
      icon: Icons.stars_rounded,
      iconColor: AppColors.warning500,
    );
    if (quest.rewardBadgeId == null) return points;
    return Row(
      children: [
        Expanded(child: points),
        AppSpace.wGapMd,
        Expanded(
          child: AppStatTile(
            label: 'Badge',
            value: 'Included',
            icon: Icons.emoji_events_outlined,
            iconColor: AppColors.tagAirdrop,
          ),
        ),
      ],
    );
  }
}

/// The quest's link and a button that opens it.
class QuestLinkSection extends StatelessWidget {
  const QuestLinkSection({
    super.key,
    required this.url,
    required this.buttonLabel,
    required this.onOpen,
  });

  final String url;
  final String buttonLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return QuestSectionCard(
      icon: Icons.link_rounded,
      label: 'Link',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            url,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(AppColors.primary400),
          ),
          AppSpace.gapMd,
          AppButton(
            label: buttonLabel,
            icon: Icons.open_in_new_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
