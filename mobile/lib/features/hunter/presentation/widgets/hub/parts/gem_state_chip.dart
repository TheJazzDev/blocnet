import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_pill.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// `CURRENT`, `DUE` or `QUIET` at the end of a gem's header line.
class GemStateChip extends StatelessWidget {
  const GemStateChip({super.key, required this.chip});

  final GemChip chip;

  @override
  Widget build(BuildContext context) {
    return switch (chip) {
      GemChip.current => const HubPill.neutral(label: 'Current'),
      GemChip.due => HubPill(label: 'Due', color: HubTone.due),
      GemChip.quiet => const HubPill(label: 'Quiet', color: HubTone.quiet),
    };
  }
}
