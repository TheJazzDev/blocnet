import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// How many members asked for an update. A count only — no member names
/// reach the hunter.
class GemWaitCard extends StatelessWidget {
  const GemWaitCard({super.key, required this.waiting});

  final int waiting;

  @override
  Widget build(BuildContext context) {
    final headline = waiting == 1
        ? '1 member is waiting'
        : '${groupedCount(waiting)} members are waiting';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.quietTop,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.quietOrange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote_rounded,
                  size: 16, color: AppColors.quietOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headline,
                  style: HubType.rowTitle(AppColors.zincStrong),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'They asked for an update this week. One post clears all of '
            "them — they're notified the moment you publish.",
            style: HubType.meta(AppColors.zincFaint).copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }
}

/// Open reports against the gem — the one red surface on the page.
class GemReportCard extends StatelessWidget {
  const GemReportCard({super.key, required this.reports});

  final int reports;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.hubCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.moderationAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, size: 16, color: AppColors.reportRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              counted(reports, 'report'),
              style: HubType.rowTitle(AppColors.zincStrong),
            ),
          ),
          // The only report members can raise on a gem is "inactive".
          Text('Unmaintained', style: HubType.meta(AppColors.zincFaint)),
        ],
      ),
    );
  }
}

/// `⋯ 19 days without an update`, drawn as a gap rather than hidden.
class GemGapCard extends StatelessWidget {
  const GemGapCard({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.quietTop,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.quietOrange.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.more_horiz_rounded,
              size: 16, color: AppColors.quietOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${counted(days, 'day')} without an update',
              style: HubType.meta(AppColors.zincBody),
            ),
          ),
        ],
      ),
    );
  }
}
