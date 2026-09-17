import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// The three measures, one line each, under `HOW RELIABILITY IS MEASURED`.
class ReliabilityExplainer extends StatelessWidget {
  const ReliabilityExplainer({super.key});

  static const lines = [
    'Coverage — gems updated in the last 14 days.',
    'Response — asks that got an update within a week.',
    'Cadence — your typical days between updates.',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HubInsets.gutter),
      child: Text(
        lines.join('\n'),
        style: HubType.body(AppColors.textMuted, height: 1.6),
      ),
    );
  }
}
