import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/reliability_metrics.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_pill.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// The three physiques of the reliability card.
enum ReliabilityCardStyle { reliable, slipping, unscored }

/// Reliability as the platform observes it: standing, coverage as a
/// fraction and a sentence, one pip per gem, then response, cadence and
/// waiting. The unscored style carries a sentence and nothing else — nothing
/// is scored before there is something to report.
class ReliabilityCard extends StatelessWidget {
  const ReliabilityCard({
    super.key,
    required this.style,
    required this.standingLabel,
    required this.sentence,
    this.trailingLabel,
    this.currentCount = 0,
    this.gemCount = 0,
    this.pips = const [],
    this.metrics,
  });

  final ReliabilityCardStyle style;
  final String standingLabel;
  final String? trailingLabel;
  final String sentence;
  final int currentCount;
  final int gemCount;
  final List<CoveragePip> pips;

  /// Null for the unscored style.
  final ReliabilityMetricValues? metrics;

  bool get _scored => style != ReliabilityCardStyle.unscored;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _standingPill(),
              const Spacer(),
              if (trailingLabel != null)
                Text(
                  trailingLabel!.toUpperCase(),
                  style: HubType.caps(AppColors.zincCaption),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_scored) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$currentCount of $gemCount',
                  style: AppTypography.custom(
                    size: 32,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.96,
                    height: 1,
                  ).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'gems current',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HubType.body(AppColors.zincMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Text(sentence, style: HubType.meta(AppColors.zincFaint)),
          if (_scored && pips.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Pips(pips: pips),
          ],
          if (_scored && metrics != null) ReliabilityMetrics(values: metrics!),
        ],
      ),
    );
  }

  BoxDecoration _decoration() {
    switch (style) {
      case ReliabilityCardStyle.reliable:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.reliableTop, AppColors.reliableBottom],
          ),
          border: Border.all(color: AppColors.chainIce.withValues(alpha: 0.18)),
        );
      case ReliabilityCardStyle.slipping:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.slippingTop, AppColors.slippingBottom],
          ),
          border:
              Border.all(color: AppColors.quietOrange.withValues(alpha: 0.2)),
        );
      case ReliabilityCardStyle.unscored:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.hubCard,
          border: Border.all(color: AppColors.hubCardEdge),
        );
    }
  }

  Widget _standingPill() {
    const padding = EdgeInsets.symmetric(horizontal: 9, vertical: 4);
    switch (style) {
      case ReliabilityCardStyle.reliable:
        return HubPill(
          label: standingLabel,
          color: AppColors.hunterSoft,
          background: AppColors.chainIce.withValues(alpha: 0.12),
          padding: padding,
          tracking: 1.32,
        );
      case ReliabilityCardStyle.slipping:
        return HubPill(
          label: standingLabel,
          color: AppColors.quietOrange,
          background: AppColors.quietOrange.withValues(alpha: 0.12),
          padding: padding,
          tracking: 1.32,
        );
      case ReliabilityCardStyle.unscored:
        return HubPill(
          label: standingLabel,
          color: AppColors.zincMuted,
          background: AppColors.borderSubtle,
          padding: padding,
          tracking: 1.32,
        );
    }
  }
}

class _Pips extends StatelessWidget {
  const _Pips({required this.pips});

  final List<CoveragePip> pips;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('hub-pips'),
      children: [
        for (var i = 0; i < pips.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              key: ValueKey('hub-pip-${pips[i].name}'),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: pips[i] == CoveragePip.current
                    ? AppColors.chainIce
                    : AppColors.quietOrange,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
