import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/notifications/data/models/digest_summary_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:flutter/material.dart';

class NotificationInsightsScreen extends StatelessWidget {
  const NotificationInsightsScreen({
    super.key,
    this.digest,
  });

  final DigestSummary? digest;

  @override
  Widget build(BuildContext context) {
    final summary = digest;
    final hasInsights = summary?.hasAnyInsight == true;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Insights',
        backButton: true,
        showSearch: false,
        showFilter: false,
        showNotificationBell: false,
      ),
      body: !hasInsights
          ? const _EmptyInsightsState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Text(
                  'Your ${summary!.windowDays}-day notification insights',
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 17,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (summary.missedHighUrgency.isNotEmpty) ...[
                  const _InsightsSectionLabel('Missed High Urgency'),
                  const SizedBox(height: 6),
                  ...summary.missedHighUrgency.take(6).map(
                        (entry) => _InsightsLine(
                          title: entry.title,
                          subtitle: entry.projectName,
                        ),
                      ),
                  const SizedBox(height: 14),
                ],
                if (summary.activeProjects.isNotEmpty) ...[
                  const _InsightsSectionLabel('Most Active Projects'),
                  const SizedBox(height: 6),
                  ...summary.activeProjects.take(6).map(
                        (entry) => _InsightsLine(
                          title: entry.projectName,
                          subtitle:
                              '${entry.newCount} updates · ${entry.highCount} high urgency',
                        ),
                      ),
                  const SizedBox(height: 14),
                ],
                if (summary.topCommunityPosts.isNotEmpty) ...[
                  const _InsightsSectionLabel('Top Community Threads'),
                  const SizedBox(height: 6),
                  ...summary.topCommunityPosts.take(6).map(
                        (entry) => _InsightsLine(
                          title: entry.contentPreview,
                          subtitle:
                              '${entry.likesCount} likes · ${entry.commentsCount} comments',
                        ),
                      ),
                ],
              ],
            ),
    );
  }
}

class _InsightsSectionLabel extends StatelessWidget {
  const _InsightsSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.custom(
        color: AppColors.textFaint,
        size: 10,
        weight: FontWeight.w700,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _InsightsLine extends StatelessWidget {
  const _InsightsLine({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 12,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 11,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInsightsState extends StatelessWidget {
  const _EmptyInsightsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              color: AppColors.textFaint,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              'No insights yet',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 15,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your recap will appear here once there is enough activity.',
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
