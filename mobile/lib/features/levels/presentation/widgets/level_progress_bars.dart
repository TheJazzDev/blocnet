import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/domain/level_number_format.dart';
import 'package:blocnet/features/levels/domain/level_requirement.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_requirement_row.dart';
import 'package:flutter/material.dart';

/// The outstanding metrics towards the next level, one thin bar each,
/// capped at [maxBars] with a "+N more" line.
class LevelProgressBars extends StatelessWidget {
  const LevelProgressBars({
    super.key,
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
      return LevelNoteLine(
        icon: Icons.check_circle_rounded,
        text: 'All requirements met. Refresh to level up.',
        color: AppColors.successColor,
      );
    }

    final shown = incomplete.take(maxBars).toList();
    final hidden = incomplete.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final metric in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _MetricBar(metric: metric, tierColor: tierColor),
          ),
        if (hidden > 0)
          Text(
            '+$hidden more requirement${hidden == 1 ? '' : 's'}',
            style: AppText.caption(AppColors.textFaint),
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

/// An icon and a short sentence, flat, no box.
class LevelNoteLine extends StatelessWidget {
  const LevelNoteLine({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppIcon.sm, color: color),
        AppSpace.wGapSm,
        Expanded(
          child: Text(text, style: AppText.label(AppColors.textSecondary)),
        ),
      ],
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({required this.metric, required this.tierColor});

  final _NamedMetric metric;
  final Color tierColor;

  @override
  Widget build(BuildContext context) {
    final value = metric.value;
    final fraction = value.percentage.clamp(0, 100) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(metric.metric.icon,
                size: AppIcon.xs, color: AppColors.textMuted),
            AppSpace.wGapSm,
            Expanded(
              child: Text(
                metric.metric.shortLabel,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(AppColors.textSecondary),
              ),
            ),
            Text(
              '${formatCompactRaw(value.current)} / ${formatCompactRaw(value.required)}',
              style:
                  AppText.caption(AppColors.textMuted, weight: AppText.semibold)
                      .merge(AppText.tabular),
            ),
          ],
        ),
        AppSpace.gapXs,
        LinearProgressIndicator(
          value: fraction,
          minHeight: 4,
          borderRadius: AppRadius.full,
          backgroundColor: AppColors.bgElevated,
          valueColor: AlwaysStoppedAnimation<Color>(tierColor),
        ),
      ],
    );
  }
}

class _NamedMetric {
  const _NamedMetric(this.metric, this.value);

  final LevelMetric metric;
  final ProgressMetric value;
}
