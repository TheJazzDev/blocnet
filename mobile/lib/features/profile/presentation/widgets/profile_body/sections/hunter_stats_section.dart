import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/profile_hunter_metrics.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/widgets/hunter_stat_card.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/features/profile/presentation/widgets/trust_chips.dart';
import 'package:flutter/material.dart';

/// Success rate + sentiment cards and the activity chips.
///
/// Only rendered once the hunter has posted at least one update — before that
/// every number here is a zero, and `HunterFirstRunSection` stands in its
/// place. Labels are spelled out rather than abbreviated: a stat row should
/// not need a glossary.
class HunterStatsSection extends StatelessWidget {
  const HunterStatsSection({super.key, required this.metrics});

  final HunterProfileMetrics metrics;

  static const Color _sentimentColor = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    final updates = metrics.hunterUpdates;
    final median = metrics.medianHoursBetweenUpdates;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Hunter stats'),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              HunterStatCard(
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.primary400,
                label: 'Success Rate',
                value: '${metrics.successRate}%',
                footnote: '${updates.length} updates tracked',
              ),
              const SizedBox(width: AppSpace.sm),
              HunterStatCard(
                icon: Icons.thumb_up_alt_outlined,
                iconColor: _sentimentColor,
                label: 'Sentiment',
                value: metrics.sentiment.label,
                valueSize: AppText.labelSize,
                footnote: metrics.sentiment.footnote,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Success rate is the share of your updates posted at medium or '
            'high priority. Sentiment weighs your high-priority calls against '
            'your low-priority ones.',
            style: AppText.caption(AppColors.textFaint),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              TrustChip(
                label: 'Updates, last 7 days',
                value: '${metrics.updatesLast7d}',
              ),
              TrustChip(
                label: 'Updates, last 30 days',
                value: '${metrics.updatesLast30d}',
              ),
              TrustChip(
                label: 'High priority, last 30 days',
                value: '${metrics.highUrgencyShare30d.toStringAsFixed(0)}%',
              ),
              if (median != null)
                TrustChip(
                  label: 'Median gap between updates',
                  value: '${median.toStringAsFixed(1)}h',
                ),
              TrustChip(
                label: 'Last update',
                value: _lastUpdateLabel(metrics.lastActiveAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _lastUpdateLabel(DateTime? lastActiveAt) {
    if (lastActiveAt == null) return 'Never';

    final elapsed = DateTime.now().difference(lastActiveAt);
    if (elapsed.inHours < 1) return 'Just now';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    return '${elapsed.inDays}d ago';
  }
}
