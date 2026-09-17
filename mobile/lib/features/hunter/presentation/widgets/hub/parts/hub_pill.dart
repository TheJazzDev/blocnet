import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// A small outlined pill carrying an upper-case word — `HUNTER`,
/// `RELIABLE`, `INVITE`, `IN REVIEW`, a gem's state — drawn like the old
/// feed's `HIGH` / `HUNTER` / `AIRDROPS` pills: a faint tint, a coloured
/// hairline, coloured text.
class HubPill extends StatelessWidget {
  const HubPill({
    super.key,
    required this.label,
    required this.color,
    this.neutral = false,
  });

  /// A grey pill for states that ask nothing (`CURRENT`, `IN REVIEW`, `NEW`).
  const HubPill.neutral({super.key, required this.label})
      : color = null,
        neutral = true;

  final String label;
  final Color? color;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
      decoration: BoxDecoration(
        color: neutral ? AppColors.bgElevated : tint.withValues(alpha: 0.1),
        borderRadius: AppRadius.full,
        border: Border.all(
          color: neutral ? AppColors.borderMuted : tint.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        style: HubType.caps(tint, tracking: 0.6),
      ),
    );
  }
}
