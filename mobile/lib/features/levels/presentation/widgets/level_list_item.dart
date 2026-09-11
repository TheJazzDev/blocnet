import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_status_chip.dart';
import 'package:flutter/material.dart';

/// Compact row for a level inside a tier section (list view mode).
///
/// Locked levels are dimmed but keep a tier-coloured accent bar so the
/// section still reads as one colour block.
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
    final accentAlpha = isLocked ? 0.3 : 0.9;

    return Material(
      color: isCurrent ? tierColor.withValues(alpha: 0.08) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 3,
                color: tierColor.withValues(alpha: isCurrent ? 1 : accentAlpha),
              ),
            ),
          ),
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
              const SizedBox(width: 10),
              Expanded(child: _buildText()),
              const SizedBox(width: 8),
              _buildTrailing(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          level.name,
          style: AppTypography.custom(
            color: isLocked ? AppColors.textMuted : AppColors.textPrimary,
            size: 13,
            weight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'Level ${level.level}',
          style: AppTypography.custom(
            color: isLocked ? AppColors.textFaint : tierColor,
            size: 11,
            weight: FontWeight.w600,
          ),
        ),
        if (!isLocked && level.description.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            level.description,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: 10,
              weight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing() {
    if (isCurrent) {
      return LevelStatusChip(label: 'CURRENT', color: tierColor);
    }
    if (isLocked) {
      return Icon(
        Icons.lock_outline_rounded,
        size: 16,
        color: tierColor.withValues(alpha: 0.55),
      );
    }
    return Icon(
      Icons.check_circle_rounded,
      size: 16,
      color: tierColor.withValues(alpha: 0.85),
    );
  }
}
