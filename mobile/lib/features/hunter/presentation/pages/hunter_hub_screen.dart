import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hunter_stats_grid.dart';
import 'package:blocnet/features/hunter/presentation/widgets/managed_projects_row.dart';
import 'package:blocnet/features/hunter/presentation/widgets/season_leaderboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HunterHubScreen extends StatelessWidget {
  const HunterHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const HunterStatsGrid(),
                const SizedBox(height: 24),
                _SectionHeader(title: 'Manage My Projects'),
                const SizedBox(height: 12),
                const ManagedProjectsRow(),
                const SizedBox(height: 24),
                _SectionHeader(title: 'Season Ranking'),
                const SizedBox(height: 12),
                const SeasonLeaderboard(),
                const SizedBox(height: 24),
                _EliteHunterBanner(),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Elite hunter promotional banner
// ─────────────────────────────────────────────────────────────────────────────

class _EliteHunterBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary500.withValues(alpha: 0.12),
            AppColors.primary500.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.verified_rounded,
              color: AppColors.primary400,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elite Hunter Status',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.primary400,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Maintain 85%+ success rate to keep Elite status',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.primary400.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
