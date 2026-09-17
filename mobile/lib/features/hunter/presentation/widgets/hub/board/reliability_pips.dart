import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// One thin segment per gem: accent when current, orange when it needs the
/// hunter — thin bars like the old mining progress bar.
class ReliabilityPips extends StatelessWidget {
  const ReliabilityPips({super.key, required this.pips});

  final List<CoveragePip> pips;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('hub-pips'),
      children: [
        for (var i = 0; i < pips.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: Container(
              key: ValueKey('hub-pip-${pips[i].name}'),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: pips[i] == CoveragePip.current
                    ? HubTone.accent.withValues(alpha: 0.85)
                    : HubTone.quiet,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
