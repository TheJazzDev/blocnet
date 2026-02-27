import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:flutter/material.dart';

class MiningHourlyHistoryCard extends StatelessWidget {
  const MiningHourlyHistoryCard({
    super.key,
    required this.entries,
    required this.isLoading,
    this.maxEntries = 12,
  });

  final List<MiningHourlyCheckpointModel> entries;
  final bool isLoading;
  final int? maxEntries;

  @override
  Widget build(BuildContext context) {
    final visibleEntries = maxEntries == null
        ? entries
        : entries.take(maxEntries!).toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hourly Mining History',
            style: AppTypography.custom(
              size: 16,
              weight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Latest checkpoint earnings by hour',
            style: AppTypography.custom(
              size: 12,
              weight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading && visibleEntries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary400,
                  ),
                ),
              ),
            )
          else if (visibleEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No hourly checkpoints yet. Start mining to generate hourly records.',
                style: AppTypography.custom(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            )
          else
            ...visibleEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return Column(
                children: [
                  _HistoryRow(item: row),
                  if (index != visibleEntries.length - 1)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.borderSubtle.withValues(alpha: 0.3),
                            AppColors.borderSubtle,
                            AppColors.borderSubtle.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final MiningHourlyCheckpointModel item;

  @override
  Widget build(BuildContext context) {
    final rangeLabel = _formatRange(item.hourStartAt, item.hourEndAt);
    final statusColor =
        item.isClaimed ? AppColors.successColor : AppColors.primary500;
    final statusLabel = item.isClaimed ? 'Claimed' : 'Unclaimed';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rangeLabel,
                style: AppTypography.custom(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Hour ${item.hourIndex}  ·  Boost ${item.boostBpsSnapshot} bps  ·  Ref ${item.activeReferralsSnapshot}',
                style: AppTypography.custom(
                  size: 11.5,
                  weight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${item.points} MCR',
              style: AppTypography.custom(
                size: 14,
                weight: FontWeight.w800,
                color: AppColors.successColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                statusLabel,
                style: AppTypography.custom(
                  size: 10,
                  weight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatRange(DateTime? startAt, DateTime? endAt) {
    if (startAt == null || endAt == null) return 'Unknown hour';
    final start = _formatClock(startAt);
    final end = _formatClock(endAt);
    return '${_formatDate(startAt)}  ·  $start - $end';
  }

  String _formatDate(DateTime date) {
    final month = _monthName(date.month);
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day';
  }

  String _formatClock(DateTime date) {
    final hour24 = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    final hour12Raw = hour24 % 12;
    final hour12 = hour12Raw == 0 ? 12 : hour12Raw;
    return '$hour12:$minute $suffix';
  }

  String _monthName(int month) {
    const names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '---';
    return names[month - 1];
  }
}
