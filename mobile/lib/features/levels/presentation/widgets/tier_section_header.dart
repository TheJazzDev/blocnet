import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_status_chip.dart';
import 'package:flutter/material.dart';

/// Heading for one tier: colour swatch, tier name, level range and a status
/// pill describing how far the user is through the tier.
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.hair, AppSpace.xs, AppSpace.hair, AppSpace.sm),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.smValue),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            tier.name,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.labelSize,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              '${tier.rangeLabel} · ${tier.shape}',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.captionSize,
                weight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
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
        label: 'COMPLETE',
        color: color,
        filled: false,
        icon: Icons.check_rounded,
      );
    }
    if (unlocked == 0) {
      return LevelStatusChip(
        label: 'LOCKED',
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
