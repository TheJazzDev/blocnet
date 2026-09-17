import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_progress_bars.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_status_chip.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// The user's current level and what is left for the next one, on a flat
/// card. The tier colour appears only in the pill and the bars.
class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({
    super.key,
    required this.progress,
    this.onTap,
    this.maxBars = 3,
  });

  final UserLevelProgressModel progress;
  final VoidCallback? onTap;

  /// How many incomplete metrics to show as bars before truncating.
  final int maxBars;

  @override
  Widget build(BuildContext context) {
    final current = progress.currentLevel;
    final next = progress.nextLevel;
    final tierColor = current.tierColor;

    return AppSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Your level',
            icon: Icons.military_tech_outlined,
            padding: const EdgeInsets.only(bottom: AppSpace.md),
          ),
          _CurrentLevelRow(
            level: current,
            tierColor: tierColor,
            showChevron: onTap != null,
          ),
          AppSpace.gapMd,
          Divider(height: 1, color: AppColors.borderSubtle),
          AppSpace.gapMd,
          if (next == null)
            LevelNoteLine(
              icon: Icons.emoji_events_rounded,
              text: 'Top level reached.',
              color: tierColor,
            )
          else ...[
            Text(
              'Next: ${next.name} · Level ${next.level}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                AppColors.textSecondary,
                weight: AppText.semibold,
              ),
            ),
            AppSpace.gapSm,
            LevelProgressBars(
              progressToNext: progress.progressToNext,
              tierColor: tierColor,
              maxBars: maxBars,
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrentLevelRow extends StatelessWidget {
  const _CurrentLevelRow({
    required this.level,
    required this.tierColor,
    required this.showChevron,
  });

  final UserLevelModel level;
  final Color tierColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LevelBadge(
          level: level,
          size: LevelBadgeSize.large,
          showName: false,
          showLevelNumber: false,
        ),
        AppSpace.wGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.subtitle(
                  AppColors.textPrimary,
                  weight: AppText.bold,
                ),
              ),
              AppSpace.gapXs,
              Row(
                children: [
                  LevelStatusChip(
                    label: level.tier.name,
                    color: tierColor,
                    filled: false,
                  ),
                  AppSpace.wGapSm,
                  Flexible(
                    child: Text(
                      'Level ${level.level}',
                      style: AppText.label(AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showChevron)
          Icon(
            Icons.chevron_right_rounded,
            size: AppIcon.md,
            color: AppColors.textFaint,
          ),
      ],
    );
  }
}
