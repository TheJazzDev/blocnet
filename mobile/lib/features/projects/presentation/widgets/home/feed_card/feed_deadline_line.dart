import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// When the window an update describes closes, stated once as a fact.
///
/// Round six removed a live countdown, its red panel and a draining progress
/// bar, and the reasoning is the product's rather than a matter of taste. **The
/// hunter already knows when the window shuts and says so when they post**, so
/// a clock ticking to the second adds no information and implies a precision
/// the platform is not entitled to. The bar was worse than redundant: its full
/// width could only represent the window's *total length*, which nobody outside
/// the project knows — the same thing that got an earlier phase rail withdrawn.
///
/// So: one line, quiet, no animation. Only the closing-today case takes any
/// emphasis, and it takes it in weight and brightness rather than colour,
/// because on a high-priority card the red edge is already spent.
class FeedDeadlineLine extends StatelessWidget {
  const FeedDeadlineLine({
    super.key,
    required this.deadlineAt,
    this.now,
  });

  final DateTime deadlineAt;

  /// Injectable so the four renderings can be asserted without waiting for a
  /// real clock to reach them.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final phrasing = describeDeadline(deadlineAt, now ?? DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            phrasing.hasPassed ? Icons.history_rounded : Icons.schedule_rounded,
            size: AppIcon.sm,
            color:
                phrasing.hasPassed ? AppColors.textFaint : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              phrasing.label,
              style: AppTypography.custom(
                color: phrasing.hasPassed
                    ? AppColors.textFaint
                    : phrasing.isToday
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                size: AppText.bodySize,
                weight: phrasing.isToday ? FontWeight.w700 : FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four states a deadline can be in on a card.
@immutable
class DeadlinePhrasing {
  const DeadlinePhrasing({
    required this.label,
    required this.isToday,
    required this.hasPassed,
  });

  final String label;
  final bool isToday;
  final bool hasPassed;
}

/// Puts a deadline into words, the way a hunter would say it.
///
/// Never a countdown. "Closes tonight" rather than "closes in 6h 12m", because
/// the second implies the app is tracking a clock it does not own.
DeadlinePhrasing describeDeadline(DateTime deadlineAt, DateTime now) {
  final deadline = deadlineAt.toLocal();
  final local = now.toLocal();

  if (deadline.isBefore(local)) {
    final ago = local.difference(deadline);
    return DeadlinePhrasing(
      label: 'Window closed ${_roughly(ago)} ago',
      isToday: false,
      hasPassed: true,
    );
  }

  final today = DateTime(local.year, local.month, local.day);
  final closesOn = DateTime(deadline.year, deadline.month, deadline.day);
  final daysOut = closesOn.difference(today).inDays;

  if (daysOut == 0) {
    // The only case allowed emphasis: it shuts before the day is out.
    return DeadlinePhrasing(
      label: deadline.hour >= 17
          ? 'Closes tonight'
          : 'Closes today, ${_clock(deadline)}',
      isToday: true,
      hasPassed: false,
    );
  }
  if (daysOut == 1) {
    return DeadlinePhrasing(
      label: 'Closes tomorrow, ${_clock(deadline)}',
      isToday: false,
      hasPassed: false,
    );
  }
  if (daysOut < 7) {
    return DeadlinePhrasing(
      label: 'Closes ${_weekday(deadline)}, ${_clock(deadline)}',
      isToday: false,
      hasPassed: false,
    );
  }
  return DeadlinePhrasing(
    label: 'Closes ${_date(deadline)}',
    isToday: false,
    hasPassed: false,
  );
}

String _roughly(Duration d) {
  if (d.inDays >= 14) return '${(d.inDays / 7).floor()} weeks';
  if (d.inDays >= 1) return '${d.inDays} ${d.inDays == 1 ? 'day' : 'days'}';
  if (d.inHours >= 1) {
    return '${d.inHours} ${d.inHours == 1 ? 'hour' : 'hours'}';
  }
  return 'minutes';
}

String _clock(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final suffix = d.hour < 12 ? 'am' : 'pm';
  if (d.minute == 0) return '$hour$suffix';
  return '$hour:${d.minute.toString().padLeft(2, '0')}$suffix';
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
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

String _weekday(DateTime d) => _weekdays[d.weekday - 1];

String _date(DateTime d) => '${d.day} ${_months[d.month - 1]}';
