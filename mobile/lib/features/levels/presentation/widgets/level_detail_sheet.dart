import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:flutter/material.dart';

/// Bottom sheet showing detailed level information and requirements
class LevelDetailSheet extends StatelessWidget {
  const LevelDetailSheet({
    super.key,
    required this.level,
    required this.isCurrent,
    required this.isLocked,
    required this.myProgress,
  });

  final UserLevelModel level;
  final bool isCurrent;
  final bool isLocked;
  final UserLevelProgressModel? myProgress;

  static void show(
    BuildContext context, {
    required UserLevelModel level,
    required bool isCurrent,
    required bool isLocked,
    required UserLevelProgressModel? myProgress,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LevelDetailSheet(
        level: level,
        isCurrent: isCurrent,
        isLocked: isLocked,
        myProgress: myProgress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
            // Header with icon and title
            Row(
              children: [
                Opacity(
                  opacity: isLocked ? 0.5 : 1.0,
                  child: LevelBadge(
                    level: level,
                    size: LevelBadgeSize.large,
                    showName: false,
                    showLevelNumber: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isLocked)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              level.name,
                              style: AppTypography.custom(
                                color: isLocked
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                                size: 16,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Level ${level.level}',
                        style: AppTypography.custom(
                          color: AppColors.textMuted,
                          size: 12,
                          weight: FontWeight.w500,
                        ),
                      ),
                      if (isCurrent)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary500,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'YOUR CURRENT LEVEL',
                              style: AppTypography.custom(
                                color: Colors.white,
                                size: 9,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgBase,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                level.description,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: 13,
                  weight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Requirements section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isLocked ? 'Requirements to Unlock' : 'Requirements',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Requirements list
            _buildRequirement(
              icon: Icons.stars_rounded,
              label: 'BNP',
              required: _formatBnp(level.requiredBnp),
              current: _formatBnp(myProgress?.metrics.totalBnpEarned ?? '0'),
            ),
            _buildRequirement(
              icon: Icons.chat_bubble_outline,
              label: 'Comments',
              required: level.requiredComments.toString(),
              current: myProgress?.metrics.totalComments.toString() ?? '0',
            ),
            _buildRequirement(
              icon: Icons.calendar_today_outlined,
              label: 'Days Active',
              required: level.requiredDaysActive.toString(),
              current: myProgress?.metrics.totalDaysActive.toString() ?? '0',
            ),
            if (level.requiredQuests > 0)
              _buildRequirement(
                icon: Icons.flag_outlined,
                label: 'Quests Completed',
                required: level.requiredQuests.toString(),
                current: myProgress?.metrics.totalQuestsCompleted.toString() ?? '0',
              ),

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: AppTypography.custom(
                    color: Colors.white,
                    size: 14,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement({
    required IconData icon,
    required String label,
    required String required,
    required String current,
  }) {
    final currentNum = int.tryParse(current.replaceAll(',', '')) ?? 0;
    final requiredNum = int.tryParse(required.replaceAll(',', '')) ?? 0;
    final isComplete = currentNum >= requiredNum;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isComplete
                  ? AppColors.primary500.withValues(alpha: 0.15)
                  : AppColors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isComplete ? Icons.check_circle : icon,
              size: 16,
              color: isComplete ? AppColors.primary500 : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 12,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLocked
                      ? 'You have $current / $required'
                      : 'Required: $required',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 11,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (isLocked && !isComplete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                '+${_formatDiff(requiredNum - currentNum)}',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 10,
                  weight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatBnp(String value) {
    final num = int.tryParse(value) ?? 0;
    if (num >= 1000000) {
      final millions = num / 1000000;
      return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M';
    } else if (num >= 1000) {
      final thousands = num / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}K';
    }
    return num.toString();
  }

  String _formatDiff(int diff) {
    if (diff >= 1000000) {
      final millions = diff / 1000000;
      return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M';
    } else if (diff >= 1000) {
      final thousands = diff / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}K';
    }
    return diff.toString();
  }
}
