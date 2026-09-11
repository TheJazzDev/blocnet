import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Intro card: what Hunters do and what they get.
class BecomeHunterHero extends StatelessWidget {
  const BecomeHunterHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary500.withValues(alpha: 0.1),
            AppColors.primary500.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.radar_rounded, color: AppColors.primary400, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            'Join the Hunter Network',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 17,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hunters are vetted members who post Updates for the Gems they '
            'track and submit new Gems for listing. Followers tip Hunters '
            'in BNP for good calls.',
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: 12,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
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
        Icon(icon, size: 13, color: AppColors.primary400),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.custom(
            color: AppColors.primary400,
            size: 11,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
