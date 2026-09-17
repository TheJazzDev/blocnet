import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// A flat surface card with a status-tinted hairline, like the old
/// profile's sentiment card.
class _NoticeFrame extends StatelessWidget {
  const _NoticeFrame({required this.tone, required this.child, this.margin});

  final Color tone;
  final Widget child;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: AppSpace.allMd,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}

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
    return _NoticeFrame(
      tone: HubTone.quiet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote_rounded,
                  size: AppIcon.sm, color: HubTone.quiet),
              AppSpace.wGapSm,
              Expanded(
                child: Text(
                  headline,
                  style: HubType.rowTitle(AppColors.textPrimary),
                ),
              ),
            ],
          ),
          AppSpace.gapXs,
          Text(
            'They asked for an update this week. One post clears all of '
            "them — they're notified the moment you publish.",
            style: HubType.body(AppColors.textMuted),
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
    return _NoticeFrame(
      tone: HubTone.report,
      child: Row(
        children: [
          const Icon(Icons.flag_outlined,
              size: AppIcon.sm, color: HubTone.report),
          AppSpace.wGapSm,
          Expanded(
            child: Text(
              counted(reports, 'report'),
              style: HubType.rowTitle(HubTone.report),
            ),
          ),
          // The only report members can raise on a gem is "inactive".
          Text('Unmaintained', style: HubType.meta(AppColors.textFaint)),
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
    return _NoticeFrame(
      tone: HubTone.quiet,
      margin: const EdgeInsets.only(bottom: AppSpace.xl),
      child: Row(
        children: [
          const Icon(Icons.more_horiz_rounded,
              size: AppIcon.sm, color: HubTone.quiet),
          AppSpace.wGapSm,
          Expanded(
            child: Text(
              '${counted(days, 'day')} without an update',
              style: HubType.meta(HubTone.quiet, weight: AppText.semibold),
            ),
          ),
        ],
      ),
    );
  }
}
