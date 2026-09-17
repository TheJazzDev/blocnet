import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_deadline_line.dart';
import 'package:flutter/material.dart';

/// What the gem last said, then how long ago: `Farming round 2 is live ·
/// last update 19 days ago`.
class GemLastLine extends StatelessWidget {
  const GemLastLine({
    super.key,
    required this.title,
    required this.ago,
    this.agoColor,
  });

  final String title;

  /// The status colour of how long it has been; faint when null.
  final Color? agoColor;

  /// `last update 19 days ago`, or `19 days ago` in compact copy.
  final String ago;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          if (title.isNotEmpty) TextSpan(text: title),
          TextSpan(
            text: title.isEmpty ? capitalized(ago) : ' · $ago',
            style: HubType.body(agoColor ?? AppColors.textFaint,
                weight: AppText.medium),
          ),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: HubType.body(AppColors.textPrimary, weight: AppText.medium),
    );
  }
}

/// The honest version for a gem with nothing posted yet.
class GemNeverUpdatedLine extends StatelessWidget {
  const GemNeverUpdatedLine({super.key, required this.listed});

  /// `12 days ago`.
  final String listed;

  @override
  Widget build(BuildContext context) {
    return Text(
      'No updates yet · listed $listed',
      style: HubType.body(AppColors.textMuted, weight: AppText.medium),
    );
  }
}

/// The hunter's own stated closing time, worded by the Home feed's
/// formatter. Never a countdown.
class GemDeadlineLine extends StatelessWidget {
  const GemDeadlineLine({super.key, required this.at, required this.now});

  final DateTime at;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded,
              size: AppIcon.xs + 2, color: AppColors.textFaint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              describeDeadline(at, now).label,
              style: HubType.meta(AppColors.textSecondary,
                  weight: AppText.semibold),
            ),
          ),
        ],
      ),
    );
  }
}

/// `how_to_vote 31 members waiting` · `flag 2 reports`. Each part only when
/// non-zero; the report count is the only red on the screen.
class GemWaitMeta extends StatelessWidget {
  const GemWaitMeta({
    super.key,
    required this.waiting,
    required this.reports,
    required this.compact,
  });

  final int waiting;
  final int reports;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Wrap(
        spacing: AppSpace.md + 2,
        runSpacing: AppSpace.xs,
        children: [
          if (waiting > 0)
            _MetaItem(
              key: const ValueKey('gem-waiting'),
              icon: Icons.how_to_vote_rounded,
              iconColor: HubTone.accent,
              color: AppColors.textSecondary,
              label: compact
                  ? '${groupedCount(waiting)} waiting'
                  : '${counted(waiting, 'member')} waiting',
            ),
          if (reports > 0)
            _MetaItem(
              key: const ValueKey('gem-reports'),
              icon: Icons.flag_outlined,
              iconColor: HubTone.report,
              color: HubTone.report,
              label: counted(reports, 'report'),
            ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppIcon.xs + 2, color: iconColor),
        AppSpace.wGapXs,
        Text(label, style: HubType.meta(color, weight: AppText.semibold)),
      ],
    );
  }
}
