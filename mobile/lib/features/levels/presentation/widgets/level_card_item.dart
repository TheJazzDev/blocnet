import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_status_chip.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// A level as a small flat tile (card view mode); three sit side by side
/// per tier. The current level's tile gets a tier-coloured hairline.
class LevelCardItem extends StatelessWidget {
  const LevelCardItem({
    super.key,
    required this.level,
    required this.isCurrent,
    required this.isLocked,
    required this.tierColor,
    required this.onTap,
  });

  final UserLevelModel level;
  final bool isCurrent;
  final bool isLocked;
  final Color tierColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      onTap: onTap,
      padding: AppSpace.allMd,
      borderColor: isCurrent ? tierColor.withValues(alpha: 0.45) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: isLocked ? 0.4 : 1,
                child: LevelBadge(
                  level: level,
                  size: LevelBadgeSize.medium,
                  showName: false,
                  showLevelNumber: false,
                ),
              ),
              const Spacer(),
              if (!isCurrent)
                Icon(
                  isLocked
                      ? Icons.lock_outline_rounded
                      : Icons.check_circle_rounded,
                  size: AppIcon.xs,
                  color:
                      isLocked ? AppColors.textFaint : AppColors.successColor,
                ),
            ],
          ),
          AppSpace.gapSm,
          Text(
            level.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              isLocked ? AppColors.textMuted : AppColors.textPrimary,
              weight: AppText.bold,
            ),
          ),
          AppSpace.gapHair,
          SizedBox(
            // Holds either the pill or the level line at the same height so
            // tiles in a row stay aligned.
            height: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: isCurrent
                  ? FittedBox(
                      child: LevelStatusChip(
                        label: 'Current',
                        color: tierColor,
                        filled: false,
                      ),
                    )
                  : Text(
                      'Level ${level.level}',
                      style: AppText.caption(AppColors.textFaint),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
