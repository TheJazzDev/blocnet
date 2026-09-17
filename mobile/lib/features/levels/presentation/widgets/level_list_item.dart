import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_status_chip.dart';
import 'package:flutter/material.dart';

/// A level as a list row inside its tier card (list view mode): badge,
/// name, level number, a status mark and a chevron. Locked levels are
/// dimmed.
class LevelListItem extends StatelessWidget {
  const LevelListItem({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpace.row,
          child: Row(
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
              AppSpace.wGapMd,
              Expanded(child: _buildText()),
              AppSpace.wGapSm,
              _buildStatus(),
              AppSpace.wGapXs,
              Icon(
                Icons.chevron_right_rounded,
                size: AppIcon.md,
                color: AppColors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    final showDescription = !isLocked && level.description.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          level.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.body(
            isLocked ? AppColors.textMuted : AppColors.textPrimary,
            weight: AppText.bold,
          ),
        ),
        Text(
          showDescription
              ? 'Level ${level.level} · ${level.description}'
              : 'Level ${level.level}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label(AppColors.textFaint),
        ),
      ],
    );
  }

  Widget _buildStatus() {
    if (isCurrent) {
      return LevelStatusChip(label: 'Current', color: tierColor, filled: false);
    }
    return Icon(
      isLocked ? Icons.lock_outline_rounded : Icons.check_circle_rounded,
      size: AppIcon.sm,
      color: isLocked ? AppColors.textFaint : AppColors.successColor,
    );
  }
}
