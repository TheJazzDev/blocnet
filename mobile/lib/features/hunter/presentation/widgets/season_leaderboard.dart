import 'package:blocnet/app/theme.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Season leaderboard mini widget for Hunter Hub.
/// Shows rank #1, current user's rank, and the rank just below.
class SeasonLeaderboard extends StatelessWidget {
  const SeasonLeaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final username = auth.username ?? auth.displayName ?? 'You';

    // Placeholder rows — will be replaced with real API data
    final rows = [
      _LeaderboardEntry(rank: 1, username: 'CryptoWhale', tips: 9840, isCurrentUser: false),
      _LeaderboardEntry(rank: 12, username: username, tips: 4250, isCurrentUser: true),
      _LeaderboardEntry(rank: 13, username: 'GemFinder99', tips: 4100, isCurrentUser: false),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Text(
                  'RANK',
                  style: GoogleFonts.inter(
                    color: AppColors.textFaint,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Text(
                  'TIPS',
                  style: GoogleFonts.inter(
                    color: AppColors.textFaint,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            return Column(
              children: [
                _LeaderboardRow(entry: entry.value),
                if (!isLast) const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _LeaderboardEntry {
  const _LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.tips,
    required this.isCurrentUser,
  });

  final int rank;
  final String username;
  final int tips;
  final bool isCurrentUser;
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});

  final _LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final rankColor = entry.rank == 1
        ? const Color(0xFFFFD700)
        : entry.isCurrentUser
            ? AppColors.primary400
            : AppColors.textMuted;

    return Container(
      color: entry.isCurrentUser
          ? AppColors.primary500.withValues(alpha: 0.06)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.spaceGrotesk(
                color: rankColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar placeholder
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: entry.isCurrentUser
                  ? AppColors.primary500.withValues(alpha: 0.15)
                  : AppColors.bgElevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: entry.isCurrentUser
                    ? AppColors.primary500.withValues(alpha: 0.4)
                    : AppColors.borderSubtle,
              ),
            ),
            child: Center(
              child: Text(
                entry.username.isNotEmpty
                    ? entry.username[0].toUpperCase()
                    : '?',
                style: GoogleFonts.inter(
                  color: entry.isCurrentUser
                      ? AppColors.primary400
                      : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isCurrentUser ? 'You (${entry.username})' : entry.username,
                  style: GoogleFonts.inter(
                    color: entry.isCurrentUser
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: entry.isCurrentUser ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Tips
          Text(
            '${_formatTips(entry.tips)} \$BNT',
            style: GoogleFonts.spaceGrotesk(
              color: entry.isCurrentUser ? AppColors.primary400 : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTips(int tips) {
    if (tips >= 1000) {
      return '${(tips / 1000).toStringAsFixed(1)}k';
    }
    return tips.toString();
  }
}
