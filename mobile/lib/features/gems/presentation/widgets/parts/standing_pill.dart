import 'package:blocnet/features/gems/presentation/widgets/parts/gems_tone.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// `RELIABLE` / `SLIPPING` / `QUIET` / `NEW`. Nothing for a standing this
/// build does not know.
class StandingPill extends StatelessWidget {
  const StandingPill({super.key, required this.standing});

  final ReliabilityStanding standing;

  @override
  Widget build(BuildContext context) {
    if (standing == ReliabilityStanding.unknown) {
      return const SizedBox.shrink();
    }
    final color = GemsTone.standing(standing);
    if (color == null) return AppPill.caps(label: standing.label);
    return AppPill.caps(label: standing.label, color: color);
  }
}
