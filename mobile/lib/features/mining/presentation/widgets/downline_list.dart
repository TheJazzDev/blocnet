import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/shared/utils/format_number_utils.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';

class DownlineList extends StatelessWidget {
  const DownlineList({
    super.key,
    required this.items,
    required this.isLoading,
    this.maxItems = 20,
  });

  final List<DownlineMember> items;
  final bool isLoading;
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    final visibleItems = maxItems == null
        ? items
        : items.take(maxItems!).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'YOUR DOWNLINE',
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
              'Your referral downline will appear here when people join with your code.',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.captionSize,
                weight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          )
        else
          ...visibleItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: _DownlineTile(item: item),
            ),
          ),
      ],
    );
  }
}

class _DownlineTile extends StatelessWidget {
  const _DownlineTile({required this.item});

  final DownlineMember item;

  @override
  Widget build(BuildContext context) {
    final isRunning = item.status == 'running';
    final isClaimable = item.status == 'claimable';
    final statusColor = isClaimable
        ? AppColors.successColor
        : isRunning
            ? AppColors.primary400
            : AppColors.textFaint;

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
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
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
              radius: 20,
              imageUrl: item.avatarUrl,
              fallback: Text(
                _initials(item),
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.labelSize,
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
                UserNameWithLevelIcon(
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
                const SizedBox(height: AppSpace.hair),
                Text(
                  '${formatGroupedNumber(item.claimedTotalPoints, maxDecimals: 0)} claimed BNP',
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
                  item.status.toUpperCase(),
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
                    value: item.progressPct.clamp(0, 1),
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

  String _displayLabel(DownlineMember member) {
    if (member.username?.trim().isNotEmpty == true) {
      return '@${member.username!.trim().replaceAll('@', '')}';
    }
    if (member.displayName?.trim().isNotEmpty == true) {
      return member.displayName!;
    }
    return 'User';
  }

  String _initials(DownlineMember member) {
    final source = (member.username?.trim().isNotEmpty ?? false)
        ? member.username!.replaceAll('@', '')
        : ((member.displayName?.trim().isNotEmpty ?? false)
            ? member.displayName!
            : 'U');
    return source[0].toUpperCase();
  }
}
