import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_status_chip.dart';
import 'package:flutter/material.dart';

/// Small caps heading for one tier: a flat colour dot, the tier name, its
/// level range and a pill saying how far the user is through it.
class TierSectionHeader extends StatelessWidget {
  const TierSectionHeader({
    super.key,
    required this.section,
    required this.currentLevelNumber,
  });

  final LevelTierSection section;
  final int currentLevelNumber;

  @override
  Widget build(BuildContext context) {
    final tier = section.tier;
    final color = section.color;
    final unlocked =
        section.levels.where((l) => l.level <= currentLevelNumber).length;
    final total = section.levels.length;
    final caps = AppText.caption(AppColors.textFaint, weight: AppText.bold)
        .copyWith(letterSpacing: 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          Container(
            width: AppSpace.sm,
            height: AppSpace.sm,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          AppSpace.wGapSm,
          Text(tier.name.toUpperCase(), style: caps),
          AppSpace.wGapSm,
          Expanded(
            child: Text(
              tier.rangeLabel.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: caps.copyWith(fontWeight: AppText.medium),
            ),
          ),
          AppSpace.wGapSm,
          _statusChip(color: color, unlocked: unlocked, total: total),
        ],
      ),
    );
  }

  Widget _statusChip({
    required Color color,
    required int unlocked,
    required int total,
  }) {
    if (total == 0) return const SizedBox.shrink();
    if (unlocked >= total) {
      return LevelStatusChip(
        label: 'Complete',
        color: color,
        filled: false,
        icon: Icons.check_rounded,
      );
    }
    if (unlocked == 0) {
      return LevelStatusChip(
        label: 'Locked',
        color: AppColors.textFaint,
        filled: false,
        icon: Icons.lock_outline_rounded,
      );
    }
    return LevelStatusChip(
      label: '$unlocked/$total',
      color: color,
      filled: false,
    );
  }
}
