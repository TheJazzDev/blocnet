import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 3-cell stats grid shown at the top of the Hunter Hub.
/// Displays: Total Tips · Success Rate · Follower Growth
class HunterStatsGrid extends StatelessWidget {
  const HunterStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main earnings card
        _TipsCard(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _StatCard(
              label: 'Success Rate',
              value: '87%',
              icon: Icons.track_changes_rounded,
              iconColor: AppColors.successColor,
              trend: '+2.3%',
              trendPositive: true,
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(
              label: 'Followers',
              value: '12.5k',
              icon: Icons.people_outline_rounded,
              iconColor: AppColors.primary400,
              trend: '+340',
              trendPositive: true,
            )),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.diamond_outlined,
                  size: 16,
                  color: AppColors.primary400,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total Tips Earned',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Season 3',
                  style: GoogleFonts.inter(
                    color: AppColors.successColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '4,250',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '\$BNT',
                  style: GoogleFonts.inter(
                    color: AppColors.primary400,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar towards goal
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.68,
              backgroundColor: AppColors.bgElevated,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '68% of season goal · 6,250 \$BNT target',
            style: GoogleFonts.inter(
              color: AppColors.textFaint,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.trend,
    required this.trendPositive,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String trend;
  final bool trendPositive;

  @override
  Widget build(BuildContext context) {
    final trendColor = trendPositive ? AppColors.successColor : AppColors.error500;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trend,
                  style: GoogleFonts.inter(
                    color: trendColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
