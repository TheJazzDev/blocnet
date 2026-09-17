import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_parts.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One queue the hub links to.
class ModHubQueue {
  const ModHubQueue({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Null when the count is unknown (loading or failed); the row then shows
  /// no number rather than a made-up zero.
  final int? count;
}

/// The hub's queues, as list rows in one card: icon square, name, one line,
/// the waiting count as a pill, and a chevron.
class ModHubQueuesCard extends StatelessWidget {
  const ModHubQueuesCard({super.key, required this.queues});

  final List<ModHubQueue> queues;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.md,
        child: Column(
          children: [
            for (var i = 0; i < queues.length; i++) ...[
              if (i > 0)
                const ModHairline(indent: AppSpace.lg + 36 + AppSpace.md),
              _QueueRow(queue: queues[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.queue});

  final ModHubQueue queue;

  @override
  Widget build(BuildContext context) {
    final count = queue.count;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          queue.onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: AppSpace.row,
            child: Row(
              children: [
                AppIconSquare(
                    icon: queue.icon,
                    color: queue.color,
                    size: 36,
                    iconSize: AppIcon.md),
                AppSpace.wGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        queue.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ModText.rowTitle(AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpace.hair),
                      Text(
                        queue.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ModText.meta(AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (count != null && count > 0) ...[
                  AppSpace.wGapSm,
                  AppPill.caps(label: '$count', color: queue.color),
                ],
                AppSpace.wGapXs,
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppIcon.lg,
                  color: AppColors.textFaint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
