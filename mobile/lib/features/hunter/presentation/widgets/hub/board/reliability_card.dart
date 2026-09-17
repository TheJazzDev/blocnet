import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/reliability_metrics.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/reliability_pips.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_pill.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// The three states of the reliability card.
enum ReliabilityCardStyle { reliable, slipping, unscored }

/// Reliability as the platform observes it: standing, coverage as a
/// fraction and a sentence, one pip per gem, then response, cadence and
/// waiting. The unscored style carries a sentence and nothing else — nothing
/// is scored before there is something to report.
///
/// One flat card for every state, like the old Alpha Radar card; the
/// standing shows only in its pill and icon colour.
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

  Color? get _tone => switch (style) {
        ReliabilityCardStyle.reliable => HubTone.accent,
        ReliabilityCardStyle.slipping => HubTone.quiet,
        ReliabilityCardStyle.unscored => null,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: HubInsets.gutter),
      padding: AppSpace.card,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          AppSpace.gapMd,
          if (_scored) ...[
            _coverage(),
            AppSpace.gapXs,
          ],
          Text(sentence, style: HubType.body(AppColors.textMuted)),
          if (_scored && pips.isNotEmpty) ...[
            AppSpace.gapMd,
            ReliabilityPips(pips: pips),
          ],
          if (_scored && metrics != null) ReliabilityMetrics(values: metrics!),
        ],
      ),
    );
  }

  Widget _header() {
    final tone = _tone;
    return Row(
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: AppIcon.sm,
          color: tone ?? AppColors.textFaint,
        ),
        AppSpace.wGapSm,
        if (tone == null)
          HubPill.neutral(label: standingLabel)
        else
          HubPill(label: standingLabel, color: tone),
        const Spacer(),
        if (trailingLabel != null)
          Text(
            trailingLabel!.toUpperCase(),
            style: HubType.caps(AppColors.textFaint, weight: AppText.semibold),
          ),
      ],
    );
  }

  Widget _coverage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$currentCount of $gemCount',
          style: AppText.title(AppColors.textPrimary).merge(AppText.tabular),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'gems current',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HubType.body(AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
