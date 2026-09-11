import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Intro card: what Hunters do and what they get.
class BecomeHunterHero extends StatelessWidget {
  const BecomeHunterHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary500.withValues(alpha: 0.1),
            AppColors.primary500.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xlValue),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lgValue),
            ),
            child: Icon(Icons.radar_rounded, color: AppColors.primary400, size: AppIcon.lg),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'Join the Hunter Network',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.subtitleSize,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Hunters are vetted members who post Updates for the Gems they '
            'track and submit new Gems for listing. Followers tip Hunters '
            'in BNP for good calls.',
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          const Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _Perk(icon: Icons.diamond_outlined, label: 'Earn tips'),
              _Perk(icon: Icons.bar_chart_rounded, label: 'Track your stats'),
              _Perk(icon: Icons.verified_rounded, label: 'Get verified'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppIcon.xs, color: AppColors.primary400),
        const SizedBox(width: AppSpace.xs),
        Text(
          label,
          style: AppTypography.custom(
            color: AppColors.primary400,
            size: AppText.captionSize,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
