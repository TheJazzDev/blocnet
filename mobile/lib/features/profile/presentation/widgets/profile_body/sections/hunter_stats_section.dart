import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/profile_hunter_metrics.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/features/profile/presentation/widgets/trust_chips.dart';
import 'package:flutter/material.dart';

/// Success rate + sentiment cards and the trust chips. Shown to anyone
/// with the hunter, admin, owner or dev role, in every space.
class HunterStatsSection extends StatelessWidget {
  const HunterStatsSection({super.key, required this.metrics});

  final HunterProfileMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final updates = metrics.hunterUpdates;
    final lastActive = metrics.lastActiveAt;
    final lastActiveLabel = lastActive == null
        ? 'N/A'
        : '${DateTime.now().difference(lastActive).inHours}h ago';
    final median = metrics.medianHoursBetweenUpdates;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Hunter stats'),
          const SizedBox(height: 8),
          Row(
            children: [
              _HunterStatCard(
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.primary400,
                label: 'Success Rate',
                value: '${metrics.successRate}%',
                footnote: updates.isEmpty
                    ? 'No signals yet'
                    : '${updates.length} updates tracked',
              ),
              const SizedBox(width: 8),
              _HunterStatCard(
                icon: Icons.thumb_up_alt_outlined,
                iconColor: const Color(0xFF4ADE80),
                label: 'Sentiment',
                value: metrics.sentiment.label,
                valueSize: 14,
                footnote: metrics.sentiment.footnote,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TrustChip(label: '7D', value: '${metrics.updatesLast7d}'),
              TrustChip(label: '30D', value: '${metrics.updatesLast30d}'),
              TrustChip(
                label: 'High%',
                value: '${metrics.highUrgencyShare30d.toStringAsFixed(0)}%',
              ),
              TrustChip(
                label: 'Median',
                value:
                    median == null ? 'N/A' : '${median.toStringAsFixed(1)}h',
              ),
              TrustChip(label: 'Last', value: lastActiveLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _HunterStatCard extends StatelessWidget {
  const _HunterStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.footnote,
    this.valueSize = 17,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String footnote;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgSurface,
              AppColors.bgSurface.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.06),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.2),
                    iconColor.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                  width: 1.1,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppTypography.custom(
                      color: AppColors.textFaint,
                      size: 9,
                      weight: FontWeight.w700,
                      letterSpacing: 0.55,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.custom(
                      color: iconColor,
                      size: valueSize,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    footnote,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.custom(
                      color: AppColors.textFaint,
                      size: 9,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
