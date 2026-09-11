import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/domain/level_number_format.dart';
import 'package:blocnet/features/levels/domain/level_requirement.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_requirement_row.dart';
import 'package:flutter/material.dart';

/// Compact card with the user's current level and the outstanding progress
/// towards the next one, tinted with the current tier's colour.
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

    return Material(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(AppRadius.lgValue),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lgValue),
            border: Border.all(color: tierColor.withValues(alpha: 0.3)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tierColor.withValues(alpha: 0.12),
                tierColor.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CurrentLevelRow(
                level: current,
                tierColor: tierColor,
                showChevron: onTap != null,
              ),
              if (next == null)
                _Banner(
                  icon: Icons.emoji_events_rounded,
                  text: 'Max level reached — you have completed every tier.',
                  color: tierColor,
                )
              else ...[
                const SizedBox(height: AppSpace.md),
                Divider(height: 1, color: tierColor.withValues(alpha: 0.2)),
                const SizedBox(height: AppSpace.md),
                _NextLevelRow(next: next, tierColor: tierColor),
                const SizedBox(height: AppSpace.sm),
                _ProgressBars(
                  progressToNext: progress.progressToNext,
                  tierColor: tierColor,
                  maxBars: maxBars,
                ),
              ],
            ],
          ),
        ),
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
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level.name,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.bodySize,
                  weight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpace.hair),
              Text(
                'Level ${level.level} · ${level.tier.name} tier',
                style: AppTypography.custom(
                  color: tierColor,
                  size: AppText.captionSize,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (showChevron)
          Icon(Icons.chevron_right_rounded, size: AppIcon.md, color: AppColors.textMuted),
      ],
    );
  }
}

class _NextLevelRow extends StatelessWidget {
  const _NextLevelRow({required this.next, required this.tierColor});

  final UserLevelModel next;
  final Color tierColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.flag_outlined, size: AppIcon.sm, color: tierColor),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            'Next: ${next.name} · Level ${next.level}',
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: AppText.captionSize,
              weight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ProgressBars extends StatelessWidget {
  const _ProgressBars({
    required this.progressToNext,
    required this.tierColor,
    required this.maxBars,
  });

  final ProgressToNext? progressToNext;
  final Color tierColor;
  final int maxBars;

  @override
  Widget build(BuildContext context) {
    final metrics = _metricsOf(progressToNext);
    final incomplete = metrics.where((m) => m.value.percentage < 100).toList();

    if (metrics.isEmpty) return const SizedBox.shrink();
    if (incomplete.isEmpty) {
      return _Banner(
        icon: Icons.check_circle_rounded,
        text: 'All requirements met — refresh to level up.',
        color: tierColor,
      );
    }

    final shown = incomplete.take(maxBars).toList();
    final hidden = incomplete.length - shown.length;

    return Column(
      children: [
        for (final metric in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _MetricBar(metric: metric, tierColor: tierColor),
          ),
        if (hidden > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '+$hidden more requirement${hidden == 1 ? '' : 's'}',
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: AppText.captionSize,
                weight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  static List<_NamedMetric> _metricsOf(ProgressToNext? next) {
    if (next == null) return const [];
    return [
      _NamedMetric(LevelMetric.bnp, next.bnp),
      _NamedMetric(LevelMetric.comments, next.comments),
      _NamedMetric(LevelMetric.daysActive, next.daysActive),
      _NamedMetric(LevelMetric.quests, next.quests),
      _NamedMetric(LevelMetric.updates, next.updates),
      _NamedMetric(LevelMetric.projects, next.projects),
    ].where((m) => parseBigInt(m.value.required) > BigInt.zero).toList();
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({required this.metric, required this.tierColor});

  final _NamedMetric metric;
  final Color tierColor;

  @override
  Widget build(BuildContext context) {
    final value = metric.value;
    final fraction = (value.percentage.clamp(0, 100)) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(metric.metric.icon, size: AppIcon.xs, color: AppColors.textMuted),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                metric.metric.shortLabel,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: AppText.captionSize,
                  weight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${formatCompactRaw(value.current)} / ${formatCompactRaw(value.required)}',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.captionSize,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 5,
            backgroundColor: AppColors.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(tierColor),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpace.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIcon.sm, color: color),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.custom(
                color: AppColors.textSecondary,
                size: AppText.captionSize,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NamedMetric {
  const _NamedMetric(this.metric, this.value);

  final LevelMetric metric;
  final ProgressMetric value;
}
