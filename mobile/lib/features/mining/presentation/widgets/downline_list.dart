import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';

class DownlineList extends StatelessWidget {
  const DownlineList({
    super.key,
    required this.items,
    required this.isLoading,
  });

  final List<DownlineMember> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
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
          ...items.take(20).map(
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
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
                        size: 11,
                        weight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
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
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
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
                      minHeight: 5,
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
