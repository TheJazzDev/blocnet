import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/profile_hunter_metrics.dart';
import 'package:flutter/material.dart';

/// Horizontal "Community voice" metric cards for hunters.
class CommunityVoiceSection extends StatelessWidget {
  const CommunityVoiceSection({super.key, required this.metrics});

  final HunterProfileMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final managed = metrics.managedProjects;
    final activeGems =
        managed.where((p) => p.posts?.isNotEmpty ?? false).length;

    final cards = [
      _MetricCard(
        icon: Icons.people_outline_rounded,
        label: 'Audience Reach',
        value: HunterProfileMetrics.compactCount(metrics.followerCount),
        text: 'Followers across your profile and gems',
      ),
      _MetricCard(
        icon: Icons.folder_open_outlined,
        label: 'Gems Managed',
        value: '${managed.length}',
        text: '$activeGems have published updates',
      ),
      _MetricCard(
        icon: Icons.bolt_outlined,
        label: 'Signals This Week',
        value: '${metrics.updatesLast7d}',
        text: '${metrics.hunterUpdates.length} total updates posted',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              Icon(Icons.forum_outlined, size: 14, color: AppColors.textFaint),
              const SizedBox(width: 6),
              Text(
                'COMMUNITY VOICE',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10,
                  weight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (_, index) => cards[index],
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemCount: cards.length,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.text,
  });

  final IconData icon;
  final String label;
  final String value;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary400),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 11,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 22,
              weight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: 10,
              weight: FontWeight.w400,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
