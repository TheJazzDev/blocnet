import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';

/// A single ranked hunter shown in the Hunter Hub season leaderboard.
class SeasonLeaderboardEntry {
  const SeasonLeaderboardEntry({
    required this.rank,
    required this.username,
    required this.updatesCount,
    required this.totalTipsReceived,
    required this.isCurrentUser,
    this.currentLevel,
  });

  final int rank;
  final String username;
  final int updatesCount;
  final double totalTipsReceived;
  final bool isCurrentUser;
  final UserLevelModel? currentLevel;
}

class SeasonLeaderboardRow extends StatelessWidget {
  const SeasonLeaderboardRow({super.key, required this.entry});

  final SeasonLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final rankColor = entry.rank == 1
        ? const Color(0xFFFFD700)
        : entry.isCurrentUser
            ? AppColors.primary400
            : AppColors.textMuted;
    final valueColor =
        entry.isCurrentUser ? AppColors.primary400 : AppColors.textSecondary;

    return Container(
      color: entry.isCurrentUser
          ? AppColors.primary500.withValues(alpha: 0.06)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#${entry.rank}',
              style: AppTypography.custom(
                color: rankColor,
                size: 13,
                weight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: UserNameWithLevelIcon(
              name: entry.isCurrentUser
                  ? 'You (${entry.username})'
                  : entry.username,
              currentLevel: entry.currentLevel,
              levelBadgeSize: LevelBadgeSize.tiny,
              iconSpacing: 4,
              textStyle: AppTypography.custom(
                color: entry.isCurrentUser
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                size: 12,
                weight: entry.isCurrentUser ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.updatesCount.toString(),
            style: AppTypography.custom(
              color: valueColor,
              size: 12,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 18),
          Text(
            _formatTipsReceived(entry.totalTipsReceived),
            style: AppTypography.custom(
              color: valueColor,
              size: 12,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTipsReceived(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}
