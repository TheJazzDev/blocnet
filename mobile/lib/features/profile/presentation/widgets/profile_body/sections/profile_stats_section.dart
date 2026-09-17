import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Four stat tiles under the hero, two per row. Each value says what it
/// counts: gems followed (the watchlist) and people followed (profile
/// follows) are separate numbers.
class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({
    super.key,
    required this.gemsFollowed,
    required this.peopleFollowed,
    required this.tipsSent,
    required this.badgeCount,
    required this.onGemsTap,
    required this.onTipsTap,
    required this.onBadgesTap,
  });

  /// Null while the first read is in flight.
  final int? gemsFollowed;
  final int peopleFollowed;
  final int tipsSent;
  final int badgeCount;
  final VoidCallback onGemsTap;
  final VoidCallback onTipsTap;
  final VoidCallback onBadgesTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppStatTile(
                  key: const ValueKey('profile-stat-gems'),
                  icon: Icons.diamond_outlined,
                  label: 'Gems followed',
                  value: gemsFollowed?.toString() ?? '—',
                  iconColor: AppColors.primary400,
                  onTap: onGemsTap,
                ),
              ),
              AppSpace.wGapSm,
              Expanded(
                child: AppStatTile(
                  key: const ValueKey('profile-stat-people'),
                  icon: Icons.people_outline_rounded,
                  label: 'People followed',
                  value: '$peopleFollowed',
                  iconColor: AppColors.tagPartnership,
                ),
              ),
            ],
          ),
          AppSpace.gapSm,
          Row(
            children: [
              Expanded(
                child: AppStatTile(
                  key: const ValueKey('profile-stat-tips'),
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Tips sent',
                  value: '$tipsSent',
                  iconColor: AppColors.successColor,
                  onTap: onTipsTap,
                ),
              ),
              AppSpace.wGapSm,
              Expanded(
                child: AppStatTile(
                  key: const ValueKey('profile-stat-badges'),
                  icon: Icons.emoji_events_outlined,
                  label: 'Badges',
                  value: '$badgeCount',
                  iconColor: AppColors.warning500,
                  onTap: onBadgesTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
