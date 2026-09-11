import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/shared/utils/format_number_utils.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
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
                size: AppText.captionSize,
                weight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.fullValue),
              ),
              child: Text(
                formatGroupedNumber(items.length, maxDecimals: 0),
                style: AppTypography.custom(
                  color: AppColors.primary400,
                  size: AppText.captionSize,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
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
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Text(
              'No mining leaderboard entries yet.',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.captionSize,
                weight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          )
        else
          ...items.take(20).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.md),
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
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
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
      padding: const EdgeInsets.all(AppSpace.lg),
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
              borderRadius: BorderRadius.circular(AppRadius.mdValue),
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
                  size: AppText.bodySize,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
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
            padding: const EdgeInsets.all(AppSpace.hair),
            child: AppAvatar(
              radius: 18,
              imageUrl: item.avatarUrl,
              fallback: Text(
                _initials(item),
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.captionSize,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: UserNameWithLevelIcon(
                        name: _displayLabel(item),
                        currentLevel: item.currentLevel,
                        levelBadgeSize: LevelBadgeSize.tiny,
                        iconSpacing: 4,
                        textStyle: AppTypography.custom(
                          color: AppColors.textPrimary,
                          size: AppText.labelSize,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (item.primaryBadge != null) ...[
                      const SizedBox(width: AppSpace.xs),
                      BadgeIcon(
                        badge: BadgeModel.fromApi(item.primaryBadge),
                        size: BadgeSize.tiny,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  '${formatGroupedNumber(item.lifetimeEarnedPoints, maxDecimals: 0)} lifetime BNP',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.captionSize,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.2),
                      statusColor.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.smValue),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  item.sessionStatus.toUpperCase(),
                  style: AppTypography.custom(
                    color: statusColor,
                    size: AppText.captionSize,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                width: 62,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.fullValue),
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

  String _displayLabel(MiningLeaderboardEntry member) {
    if (member.displayName?.trim().isNotEmpty == true) {
      return member.displayName!;
    }
    if (member.username?.trim().isNotEmpty == true) {
      return '@${member.username!}';
    }
    return member.userId;
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
