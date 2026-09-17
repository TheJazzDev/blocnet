import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Intro card: what Hunters do and what they get. A flat bordered card
/// with a small caps header, left-aligned, perks as outlined pills.
class BecomeHunterHero extends StatelessWidget {
  const BecomeHunterHero({super.key});

  @override
  Widget build(BuildContext context) {
    final hunterTint = AppColors.tagPartnership;
    return AppSurface(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_rounded, size: AppIcon.sm, color: hunterTint),
              const SizedBox(width: AppSpace.sm),
              Text(
                'HUNTERS',
                style: AppText.caption(
                  AppColors.textFaint,
                  weight: AppText.bold,
                ).copyWith(letterSpacing: 1.0),
              ),
            ],
          ),
          AppSpace.gapMd,
          Text(
            'Post updates for the gems you track',
            style: AppText.subtitle(AppColors.textPrimary, weight: AppText.bold),
          ),
          AppSpace.gapXs,
          Text(
            'Hunters keep gems current and submit new ones. Members tip '
            'them in BNP.',
            style: AppText.body(AppColors.textSecondary),
          ),
          AppSpace.gapMd,
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              AppPill(label: 'Tips', color: hunterTint, uppercase: true),
              AppPill(label: 'Stats', color: hunterTint, uppercase: true),
              AppPill(label: 'Hunter badge', color: hunterTint, uppercase: true),
            ],
          ),
        ],
      ),
    );
  }
}
