import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
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
              'Your referral downline will appear here when people join with your code.',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 11,
                weight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          )
        else
          ...visibleItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(14),
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
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.bgElevated,
              backgroundImage: (item.avatarUrl?.isNotEmpty ?? false)
                  ? NetworkImage(item.avatarUrl!)
                  : null,
              child: (item.avatarUrl?.isNotEmpty ?? false)
                  ? null
                  : Text(
                      _initials(item),
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: 12,
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
                Text(
                  item.displayName?.trim().isNotEmpty == true
                      ? item.displayName!
                      : (item.email ?? 'User'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.claimedTotalPoints} claimed pts',
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
                  item.status.toUpperCase(),
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

  String _initials(DownlineMember member) {
    final source = (member.displayName?.trim().isNotEmpty ?? false)
        ? member.displayName!
        : (member.email ?? 'U');
    return source[0].toUpperCase();
  }
}
