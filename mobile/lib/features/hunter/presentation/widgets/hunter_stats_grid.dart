import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

/// 3-cell stats grid shown at the top of the Hunter Hub.
/// Displays: Total Tips · Success Rate · Follower Growth
class HunterStatsGrid extends StatelessWidget {
  const HunterStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final updates = context.watch<UpdatesStore>().updates;
    final projects = context.watch<ProjectsStore>().projects;

    final userId = auth.userId ?? '';
    final username = auth.username ?? auth.displayName ?? '';
    final hunterUpdates = updates
        .where(
          (update) => _isCurrentHunterUpdate(
            update: update,
            userId: userId,
            username: username,
          ),
        )
        .toList();
    final managedProjects = projects
        .where(
          (project) => _isCurrentHunterProject(
            project: project,
            userId: userId,
            username: username,
          ),
        )
        .toList();

    final totalTips = hunterUpdates.fold<int>(
      0,
      (sum, update) => sum + _scoreUpdate(update),
    );

    final qualitySignals = hunterUpdates.where((update) {
      final label = update.priority.label.toLowerCase();
      return label == 'high' || label == 'mid' || label == 'medium';
    }).length;

    final successRate = hunterUpdates.isEmpty
        ? 0
        : ((qualitySignals / hunterUpdates.length) * 100).round();

    final now = DateTime.now();
    final signalsThisWeek = hunterUpdates
        .where((update) => now.difference(update.createdAt).inDays < 7)
        .length;
    final signalsLastWeek = hunterUpdates.where((update) {
      final ageInDays = now.difference(update.createdAt).inDays;
      return ageInDays >= 7 && ageInDays < 14;
    }).length;
    final momentum = signalsThisWeek - signalsLastWeek;

    final followers = _resolveFollowerCount(
      projects: managedProjects,
      updates: hunterUpdates,
    );
    final seasonGoal = _seasonGoal(totalTips);
    final progress =
        seasonGoal == 0 ? 0.0 : (totalTips / seasonGoal).clamp(0.0, 1.0);

    return Column(
      children: [
        // Main earnings card
        _TipsCard(
          totalTips: totalTips,
          progress: progress,
          seasonGoal: seasonGoal,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Success Rate',
                value: '$successRate%',
                icon: Icons.track_changes_rounded,
                iconColor: AppColors.successColor,
                trend:
                    '$qualitySignals/${hunterUpdates.length} quality signals',
                trendPositive: successRate >= 50,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Followers',
                value: _formatCompact(followers),
                icon: Icons.people_outline_rounded,
                iconColor: AppColors.primary400,
                trend: _formatMomentum(momentum),
                trendPositive: momentum >= 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  const _TipsCard({
    required this.totalTips,
    required this.progress,
    required this.seasonGoal,
  });

  final int totalTips;
  final double progress;
  final int seasonGoal;

  @override
  Widget build(BuildContext context) {
    final progressLabel = '${(progress * 100).round()}%';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.diamond_outlined,
                  size: 16,
                  color: AppColors.primary400,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total Tips Earned',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Live',
                  style: AppTypography.custom(
                    color: AppColors.successColor,
                    size: 10,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatWithCommas(totalTips),
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 28,
                  weight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '\$BNT',
                  style: AppTypography.custom(
                    color: AppColors.primary400,
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar towards goal
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bgElevated,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$progressLabel of season goal · ${_formatWithCommas(seasonGoal)} \$BNT target',
            style: AppTypography.custom(color: AppColors.textFaint,
              size: 10,
              weight: FontWeight.w400,),
          ),
        ],
      ),
    );
  }
}

bool _isCurrentHunterUpdate({
  required Update update,
  required String userId,
  required String username,
}) {
  if (userId.isNotEmpty &&
      (update.adminId == userId || update.admin?.id == userId)) {
    return true;
  }

  final updateUsername = update.admin?.username ?? update.admin?.name ?? '';
  return _normalizeIdentity(updateUsername) == _normalizeIdentity(username) &&
      _normalizeIdentity(username).isNotEmpty;
}

bool _isCurrentHunterProject({
  required Project project,
  required String userId,
  required String username,
}) {
  if (userId.isNotEmpty &&
      (project.adminId == userId || project.admin?.id == userId)) {
    return true;
  }

  final projectUsername = project.admin?.username ?? project.admin?.name ?? '';
  return _normalizeIdentity(projectUsername) == _normalizeIdentity(username) &&
      _normalizeIdentity(username).isNotEmpty;
}

String _normalizeIdentity(String value) {
  return value.replaceAll('@', '').trim().toLowerCase();
}

int _scoreUpdate(Update update) {
  final label = update.priority.label.toLowerCase();
  final base = label == 'high'
      ? 120
      : (label == 'mid' || label == 'medium')
          ? 70
          : 35;
  final followerBoost = ((update.project?.followersCount ?? 0) / 25).floor();
  return base + followerBoost;
}

int _resolveFollowerCount({
  required List<Project> projects,
  required List<Update> updates,
}) {
  final projectFollowers = projects.fold<int>(
    0,
    (sum, project) => sum + project.followersCount,
  );

  final directFollowers = updates.fold<int>(0, (maxFollowers, update) {
    final followers = update.admin?.followers ?? 0;
    if (followers > maxFollowers) return followers;
    return maxFollowers;
  });

  return directFollowers > projectFollowers
      ? directFollowers
      : projectFollowers;
}

int _seasonGoal(int totalTips) {
  const minimumGoal = 2500;
  if (totalTips <= 0) return minimumGoal;
  final rounded = ((totalTips * 1.35) / 500).ceil() * 500;
  return rounded < minimumGoal ? minimumGoal : rounded;
}

String _formatMomentum(int momentum) {
  if (momentum > 0) {
    return '+$momentum this week';
  }
  if (momentum < 0) {
    return '$momentum this week';
  }
  return 'No change this week';
}

String _formatCompact(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}

String _formatWithCommas(int value) {
  final source = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < source.length; i++) {
    final fromEnd = source.length - i;
    buffer.write(source[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.trend,
    required this.trendPositive,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String trend;
  final bool trendPositive;

  @override
  Widget build(BuildContext context) {
    final trendColor =
        trendPositive ? AppColors.successColor : AppColors.error500;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trend,
                  style: AppTypography.custom(
                    color: trendColor,
                    size: 9,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 20,
              weight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTypography.custom(color: AppColors.textMuted,
              size: 10,
              weight: FontWeight.w400,),
          ),
        ],
      ),
    );
  }
}
