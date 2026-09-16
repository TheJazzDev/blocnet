import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_pill.dart';
import 'package:flutter/material.dart';

/// `CURRENT`, `DUE` or `QUIET` at the end of a gem's header line.
class GemStateChip extends StatelessWidget {
  const GemStateChip({super.key, required this.chip});

  final GemChip chip;

  @override
  Widget build(BuildContext context) {
    switch (chip) {
      case GemChip.current:
        return const HubPill(
          label: 'Current',
          color: AppColors.zincFaint,
          background: AppColors.borderSubtle,
        );
      case GemChip.due:
        return HubPill(
          label: 'Due',
          color: AppColors.dueAmber,
          background: AppColors.dueAmber.withValues(alpha: 0.15),
        );
      case GemChip.quiet:
        return HubPill(
          label: 'Quiet',
          color: AppColors.quietOrange,
          background: AppColors.quietOrange.withValues(alpha: 0.15),
        );
    }
  }
}
