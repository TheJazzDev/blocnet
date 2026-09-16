import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/data/mine_history.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_member_parts.dart';
import 'package:flutter/material.dart';

/// `15 SEP · 132 BNP` with the outcome pill.
class MineHistoryHeader extends StatelessWidget {
  const MineHistoryHeader({super.key, required this.group});

  final MineHistoryGroup group;

  @override
  Widget build(BuildContext context) {
    final (text, ground) = switch (group.outcome) {
      MineCycleOutcome.claimed => (
          MinePalette.accentSoft,
          MinePalette.accentChip
        ),
      MineCycleOutcome.waiting => (
          MinePalette.amberText,
          MinePalette.amberChip
        ),
      MineCycleOutcome.expired => (MinePalette.faint, MinePalette.chip),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      decoration: const BoxDecoration(
        color: MinePalette.card,
        border: Border.symmetric(
          horizontal: BorderSide(color: MinePalette.rowHairline),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              group.title.toUpperCase(),
              style: AppText.label(MinePalette.muted, weight: AppText.bold)
                  .copyWith(letterSpacing: 0.8),
            ),
          ),
          MinePill(label: group.pill, text: text, ground: ground),
        ],
      ),
    );
  }
}

/// `09:00   5.5 BNP   Waiting` — struck through when expired.
class MineHistoryHourRow extends StatelessWidget {
  const MineHistoryHourRow({super.key, required this.hour});

  final MiningHourlyCheckpointModel hour;

  @override
  Widget build(BuildContext context) {
    final start = hour.hourStartAt;
    final expired = hour.isExpired;
    final stateColor = hour.isClaimed
        ? MinePalette.miningNow
        : expired
            ? MinePalette.caption
            : MinePalette.amber;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: MinePalette.hourHairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              start == null ? '--:--' : MineFormat.hour(start),
              style: AppText.body(MinePalette.faint, weight: AppText.semibold)
                  .merge(AppText.tabular),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              '${MineFormat.rate(hour.points)} BNP',
              style: AppText.body(
                expired ? MinePalette.caption : MinePalette.strong,
                weight: AppText.semibold,
              ).merge(AppText.tabular).copyWith(
                    decoration: expired ? TextDecoration.lineThrough : null,
                    decorationColor: MinePalette.caption,
                  ),
            ),
          ),
          Text(
            MineHistory.hourState(hour),
            style: AppText.label(stateColor, weight: AppText.semibold),
          ),
        ],
      ),
    );
  }
}
