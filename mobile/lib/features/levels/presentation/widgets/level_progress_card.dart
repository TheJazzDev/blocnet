import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A card widget that displays user's current level and progress to next level
class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({
    super.key,
    required this.progress,
    this.onTap,
  });

  final UserLevelProgressModel progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasNextLevel = progress.nextLevel != null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current level header
              Row(
                children: [
                  LevelBadge(
                    level: progress.currentLevel,
                    size: LevelBadgeSize.large,
                    showName: false,
                    showLevelNumber: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progress.currentLevel.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Level ${progress.currentLevel.level}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),

              if (hasNextLevel) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Next level target
                Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Next: ${progress.nextLevel!.name}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress bars
                if (progress.progressToNext != null)
                  _buildProgressSection(progress.progressToNext!),
              ] else ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Max level reached!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(ProgressToNext progressToNext) {
    final metrics = [
      _MetricProgress('BNP', progressToNext.bnp, Icons.diamond_outlined),
      _MetricProgress('Comments', progressToNext.comments, Icons.chat_bubble_outline),
      _MetricProgress('Days Active', progressToNext.daysActive, Icons.calendar_today_outlined),
      _MetricProgress('Quests', progressToNext.quests, Icons.assignment_outlined),
      _MetricProgress('Updates', progressToNext.updates, Icons.update_outlined),
      _MetricProgress('Projects', progressToNext.projects, Icons.folder_outlined),
    ];

    // Only show metrics that haven't been completed
    final incompleteMetrics = metrics.where((m) => m.metric.percentage < 100).toList();

    return Column(
      children: incompleteMetrics.isEmpty
          ? [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'All requirements met! Level up coming soon...',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green[800],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ]
          : incompleteMetrics.take(3).map((metric) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildProgressBar(
                  metric.label,
                  metric.metric,
                  metric.icon,
                ),
              );
            }).toList(),
    );
  }

  Widget _buildProgressBar(String label, ProgressMetric metric, IconData icon) {
    final percentage = metric.percentage.clamp(0, 100);
    final currentVal = _formatNumber(metric.current);
    final requiredVal = _formatNumber(metric.required);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '$currentVal / $requiredVal',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 100 ? Colors.green : Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(String value) {
    try {
      final num = int.parse(value);
      if (num >= 1000000) {
        return '${(num / 1000000).toStringAsFixed(1)}M';
      } else if (num >= 1000) {
        return '${(num / 1000).toStringAsFixed(1)}K';
      }
      return NumberFormat('#,###').format(num);
    } catch (_) {
      return value;
    }
  }
}

class _MetricProgress {
  const _MetricProgress(this.label, this.metric, this.icon);
  final String label;
  final ProgressMetric metric;
  final IconData icon;
}
