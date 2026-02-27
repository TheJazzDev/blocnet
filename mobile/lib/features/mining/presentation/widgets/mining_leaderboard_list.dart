import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';

class MiningLeaderboardList extends StatelessWidget {
  const MiningLeaderboardList({
    super.key,
    required this.items,
    required this.isLoading,
  });

  final List<MiningLeaderboardEntry> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'GLOBAL LEADERBOARD',
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: 11,
                weight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${items.length}',
                style: AppTypography.custom(
                  color: AppColors.primary400,
                  size: 11,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isLoading && items.isEmpty)
          Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.primary400,
                strokeWidth: 2,
              ),
            ),
          )
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No mining leaderboard entries yet.',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 11,
                weight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          )
        else
          ...items.take(20).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LeaderboardTile(item: item),
                ),
              ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.item});

  final MiningLeaderboardEntry item;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.sessionStatus);
    final isTop3 = item.rank <= 3;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop3
              ? AppColors.warning500.withValues(alpha: 0.3)
              : AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: isTop3
            ? [
                BoxShadow(
                  color: AppColors.warning500.withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isTop3
                  ? LinearGradient(
                      colors: [
                        AppColors.warning500.withValues(alpha: 0.2),
                        AppColors.warning500.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color:
                  isTop3 ? null : AppColors.bgElevated.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTop3
                    ? AppColors.warning500.withValues(alpha: 0.4)
                    : AppColors.borderSubtle.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '#${item.rank}',
                style: AppTypography.custom(
                  color: item.rank == 1
                      ? AppColors.warning500
                      : AppColors.textPrimary,
                  size: 14,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.15),
                  statusColor.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: AppAvatar(
              radius: 18,
              imageUrl: item.avatarUrl,
              fallback: Text(
                _initials(item),
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 11,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.displayName?.trim().isNotEmpty == true
                            ? item.displayName!
                            : (item.username?.trim().isNotEmpty == true
                                ? '@${item.username!}'
                                : item.userId),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          color: AppColors.textPrimary,
                          size: 13,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (item.primaryBadge != null) ...[
                      const SizedBox(width: 4),
                      BadgeIcon(
                        badge: BadgeModel.fromApi(item.primaryBadge),
                        size: BadgeSize.tiny,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.lifetimeEarnedPoints} lifetime MCR',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 11,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.2),
                      statusColor.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  item.sessionStatus.toUpperCase(),
                  style: AppTypography.custom(
                    color: statusColor,
                    size: 10,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 62,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: item.sessionProgressPct.clamp(0, 1),
                    backgroundColor: AppColors.bgElevated,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == 'claimable') return AppColors.successColor;
    if (status == 'running') return AppColors.primary400;
    return AppColors.textFaint;
  }

  String _initials(MiningLeaderboardEntry member) {
    final source = (member.displayName?.trim().isNotEmpty ?? false)
        ? member.displayName!
        : (member.username?.trim().isNotEmpty == true
            ? member.username!
            : member.userId);
    return source[0].toUpperCase();
  }
}
