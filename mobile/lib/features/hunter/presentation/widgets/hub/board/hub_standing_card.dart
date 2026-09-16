import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/hunter/domain/coverage_sentence.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/reliability_card.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/reliability_metrics.dart';
import 'package:flutter/material.dart';

/// Picks the reliability card's physique and words from the layout.
///
/// Standing comes from the server (14-day coverage); the fraction and pips
/// count current gems only (D1).
class HubStandingCard extends StatelessWidget {
  const HubStandingCard({super.key, required this.layout});

  final HubLayout layout;

  @override
  Widget build(BuildContext context) {
    if (layout.isDayOne) {
      return const ReliabilityCard(
        style: ReliabilityCardStyle.unscored,
        standingLabel: 'New',
        trailingLabel: 'No gems yet',
        sentence: dayOneStandingSentence,
      );
    }
    if (layout.isUnscored) {
      return const ReliabilityCard(
        style: ReliabilityCardStyle.unscored,
        standingLabel: 'New',
        sentence: unscoredSentence,
      );
    }

    final standing = layout.reliability.standing;
    final slipping = switch (standing) {
      ReliabilityStanding.reliable => false,
      ReliabilityStanding.slipping || ReliabilityStanding.quiet => true,
      _ => layout.attention.isNotEmpty,
    };
    final label = standing == ReliabilityStanding.unknown ||
            standing == ReliabilityStanding.newHunter
        ? (slipping ? 'Slipping' : 'Reliable')
        : standing.label;

    return ReliabilityCard(
      style: slipping
          ? ReliabilityCardStyle.slipping
          : ReliabilityCardStyle.reliable,
      standingLabel: label,
      trailingLabel: 'Last 14 days',
      sentence: coverageSentence(layout.board.gems),
      currentCount: layout.current.length,
      gemCount: layout.gemCount,
      pips: layout.pips,
      metrics: ReliabilityMetricValues.from(layout.reliability),
    );
  }
}
