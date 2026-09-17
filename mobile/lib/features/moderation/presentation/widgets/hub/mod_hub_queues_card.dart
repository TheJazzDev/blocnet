import 'package:blocnet/app/tokens/tokens.dart';
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
    return AppRowGroup(
      children: [for (final queue in queues) _QueueRow(queue: queue)],
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.queue});

  final ModHubQueue queue;

  @override
  Widget build(BuildContext context) {
    final count = queue.count;
    return AppListRow(
      leading: AppIconSquare(
        icon: queue.icon,
        color: queue.color,
        size: 36,
        iconSize: AppIcon.md,
      ),
      title: queue.title,
      subtitle: queue.subtitle,
      trailing: count != null && count > 0
          ? AppPill.caps(label: '$count', color: queue.color)
          : null,
      onTap: () {
        HapticFeedback.selectionClick();
        queue.onTap();
      },
    );
  }
}
