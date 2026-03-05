import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/shared/utils/format_number_utils.dart';
import 'package:flutter/material.dart';

class MiningHourlyHistoryCard extends StatelessWidget {
  const MiningHourlyHistoryCard({
    super.key,
    required this.entries,
    required this.isLoading,
    required this.basePointsPerCycle,
    required this.cycleHours,
    this.maxEntries = 12,
  });

  final List<MiningHourlyCheckpointModel> entries;
  final bool isLoading;
  final int basePointsPerCycle;
  final int cycleHours;
  final int? maxEntries;

  @override
  Widget build(BuildContext context) {
    final visibleEntries = maxEntries == null
        ? entries
        : entries.take(maxEntries!).toList(growable: false);
    if (isLoading && visibleEntries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (visibleEntries.isEmpty) {
      return Padding(
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
      );
    }

    return Column(
      children: visibleEntries.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        return Column(
          children: [
            _HistoryRow(
              item: row,
              basePointsPerCycle: basePointsPerCycle,
              cycleHours: cycleHours,
            ),
            if (index != visibleEntries.length - 1)
              Divider(
                height: 1,
                color: AppColors.borderSubtle.withValues(alpha: 0.8),
              ),
          ],
        );
      }).toList(),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.item,
    required this.basePointsPerCycle,
    required this.cycleHours,
  });

  final MiningHourlyCheckpointModel item;
  final int basePointsPerCycle;
  final int cycleHours;

  @override
  Widget build(BuildContext context) {
    final rangeLabel = _formatRange(item.hourStartAt, item.hourEndAt);
    final statusColor =
        item.isClaimed ? AppColors.successColor : AppColors.primary500;
    final statusLabel = item.isClaimed ? 'Claimed' : 'Unclaimed';
    final estimatedHourlyPoints = _estimateHourlyPoints();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rangeLabel,
                  style: AppTypography.custom(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Hour ${item.hourIndex} · Boost ${_formatBoost(item.boostBpsSnapshot)}% · ${item.activeReferralsSnapshot} refs',
                  style: AppTypography.custom(
                    size: 11,
                    weight: FontWeight.w500,
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
                '+${formatGroupedNumber(estimatedHourlyPoints, maxDecimals: 2, minDecimals: 2)} BNP',
                style: AppTypography.custom(
                  size: 13,
                  weight: FontWeight.w800,
                  color: AppColors.successColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'settled ${formatGroupedNumber(item.points, maxDecimals: 0)}',
                style: AppTypography.custom(
                  size: 10,
                  weight: FontWeight.w500,
                  color: AppColors.textFaint,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.custom(
                    size: 9,
                    weight: FontWeight.w800,
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

  double _estimateHourlyPoints() {
    final safeCycleHours = cycleHours <= 0 ? 24 : cycleHours;
    final base = basePointsPerCycle <= 0 ? 120 : basePointsPerCycle;
    final boostedCyclePoints = (base * (10000 + item.boostBpsSnapshot)) / 10000;
    return boostedCyclePoints / safeCycleHours;
  }

  String _formatRange(DateTime? startAt, DateTime? endAt) {
    if (startAt == null || endAt == null) return 'Unknown hour';
    final start = _formatClock(startAt);
    final end = _formatClock(endAt);
    return '${_formatDate(startAt)}  ·  $start - $end';
  }

  String _formatBoost(num boostBps) {
    final percent = boostBps / 100;
    return formatGroupedNumber(percent, maxDecimals: 1, minDecimals: 0);
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
