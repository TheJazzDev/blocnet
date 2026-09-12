import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// A single category pill (`AIRDROPS`, `MINING`, …) under a feed card's body.
/// These come from an update's secondary tags and carry categorical colour.
class FeedTagPill extends StatelessWidget {
  const FeedTagPill({
    super.key,required this.label});

  final String label;

  Color _colorForLabel(String lbl) {
    final lower = lbl.toLowerCase();
    if (lower.contains('alpha') || lower.contains('launch')) {
      return AppColors.tagAlpha;
    }
    if (lower.contains('partner')) {
      return AppColors.tagPartnership;
    }
    if (lower.contains('warning') || lower.contains('rug')) {
      return AppColors.tagWarning;
    }
    if (lower.contains('airdrop')) {
      return AppColors.tagAirdrop;
    }
    return AppColors.tagGeneral;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForLabel(label);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm, vertical: AppSpace.hair),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.smValue),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.custom(
          color: color,
          size: AppText.captionSize,
          weight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
