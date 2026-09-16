import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_deadline_line.dart';
import 'package:flutter/material.dart';

/// What the gem last said, then how long ago: `Farming round 2 is live ·
/// last update 19 days ago`.
class GemLastLine extends StatelessWidget {
  const GemLastLine({super.key, required this.title, required this.ago});

  final String title;

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
            style: HubType.body(AppColors.zincDim, weight: FontWeight.w500),
          ),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: HubType.body(AppColors.zincBody, weight: FontWeight.w600),
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
      style: HubType.body(AppColors.zincFaint, weight: FontWeight.w500),
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
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded,
              size: 16, color: AppColors.zincDim),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              describeDeadline(at, now).label,
              style: HubType.body(AppColors.zincBody, weight: FontWeight.w600),
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
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          if (waiting > 0)
            _MetaItem(
              key: const ValueKey('gem-waiting'),
              icon: Icons.how_to_vote_rounded,
              iconColor: AppColors.chainIce,
              color: AppColors.zincStrong,
              label: compact
                  ? '${groupedCount(waiting)} waiting'
                  : '${counted(waiting, 'member')} waiting',
            ),
          if (reports > 0)
            _MetaItem(
              key: const ValueKey('gem-reports'),
              icon: Icons.flag_outlined,
              iconColor: AppColors.reportRed,
              color: AppColors.reportRed,
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
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 5),
        Text(label, style: HubType.meta(color, weight: FontWeight.w600)),
      ],
    );
  }
}
