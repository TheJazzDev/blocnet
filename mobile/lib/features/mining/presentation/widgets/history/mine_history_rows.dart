import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/data/mine_history.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// `15 SEP · 132 BNP` with the outcome pill.
class MineHistoryHeader extends StatelessWidget {
  const MineHistoryHeader({super.key, required this.group});

  final MineHistoryGroup group;

  @override
  Widget build(BuildContext context) {
    final tone = switch (group.outcome) {
      MineCycleOutcome.claimed => MinePalette.success,
      MineCycleOutcome.waiting => MinePalette.amber,
      MineCycleOutcome.expired => MinePalette.faint,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      decoration: const BoxDecoration(
        color: MinePalette.card,
        border: Border.symmetric(
          horizontal: BorderSide(color: MinePalette.edge),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              group.title.toUpperCase(),
              style: AppText.label(MinePalette.muted, weight: AppText.bold)
                  .copyWith(letterSpacing: 1),
            ),
          ),
          AppPill.caps(label: group.pill, color: tone),
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
        ? MinePalette.success
        : expired
            ? MinePalette.faint
            : MinePalette.amber;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MinePalette.edge.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              start == null ? '--:--' : MineFormat.hour(start),
              style: AppText.label(MinePalette.faint, weight: AppText.semibold)
                  .merge(AppText.tabular),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              '${MineFormat.rate(hour.points)} BNP',
              style: AppText.body(
                expired ? MinePalette.faint : MinePalette.text,
                weight: AppText.bold,
              ).merge(AppText.tabular).copyWith(
                    decoration: expired ? TextDecoration.lineThrough : null,
                    decorationColor: MinePalette.faint,
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
