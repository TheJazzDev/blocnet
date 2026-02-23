import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/services/tips_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

/// 3-cell stats grid shown at the top of the Hunter Hub.
/// Displays live wallet tipping + update performance + followers.
class HunterStatsGrid extends StatelessWidget {
  const HunterStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final updates = context.watch<UpdatesStore>().updates;
    final projects = context.watch<ProjectsStore>().projects;
    final tipsStore = context.watch<TipsStore>();

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

    final now = DateTime.now();
    final updatesThisWeek = hunterUpdates
        .where((update) => now.difference(update.createdAt).inDays < 7)
        .length;

    final qualitySignals = hunterUpdates.where((update) {
      final label = update.priority.label.toLowerCase();
      return label == 'high' || label == 'mid' || label == 'medium';
    }).length;

    final successRate = hunterUpdates.isEmpty
        ? 0
        : ((qualitySignals / hunterUpdates.length) * 100).round();

    final followers = _resolveFollowerCount(
      projects: managedProjects,
      updates: hunterUpdates,
    );

    final receivedHistory = tipsStore.receivedHistory;
    final totalTipsReceived = _sumTipAmount(receivedHistory);
    final tipsCurrencySymbol =
        _resolveCurrencySymbol(tipsStore, receivedHistory);
    final tipBalance = _resolveTipBalance(tipsStore, receivedHistory);
    final latestTipAt = _latestTipAt(receivedHistory);

    return Column(
      children: [
        _TipsCard(
          isLoading:
              tipsStore.isLoadingReceivedHistory && receivedHistory.isEmpty,
          tipBalance: tipBalance,
          totalTipsReceived: totalTipsReceived,
          totalTipsCount: tipsStore.receivedHistoryTotal,
          currencySymbol: tipsCurrencySymbol,
          latestTipAt: latestTipAt,
          lastError: tipsStore.lastError,
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
                trend: '$updatesThisWeek updates this week',
                trendPositive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({
    required this.isLoading,
    required this.tipBalance,
    required this.totalTipsReceived,
    required this.totalTipsCount,
    required this.currencySymbol,
    required this.latestTipAt,
    required this.lastError,
  });

  final bool isLoading;
  final double tipBalance;
  final double totalTipsReceived;
  final int totalTipsCount;
  final String currencySymbol;
  final DateTime? latestTipAt;
  final String? lastError;

  @override
  Widget build(BuildContext context) {
    final symbol = currencySymbol.trim().isEmpty ? 'MCR' : currencySymbol;

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
                  Icons.volunteer_activism_rounded,
                  size: 16,
                  color: AppColors.primary400,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tip Balance',
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
                  '$totalTipsCount tx',
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
          if (isLoading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: AppColors.primary500,
                strokeWidth: 2,
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(tipBalance),
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
                    symbol,
                    style: AppTypography.custom(
                      color: AppColors.primary400,
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 2),
          Text(
            'Total received ${_formatAmount(totalTipsReceived)} $symbol from $totalTipsCount tips',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: 10,
              weight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            latestTipAt == null
                ? 'No tips received yet'
                : 'Last tip ${_formatTipRecency(latestTipAt!)}',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: 10,
              weight: FontWeight.w400,
            ),
          ),
          if (!isLoading &&
              totalTipsCount == 0 &&
              (lastError?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 4),
            Text(
              'Tip sync warning: $lastError',
              style: AppTypography.custom(
                color: AppColors.warning500,
                size: 10,
                weight: FontWeight.w500,
              ),
            ),
          ],
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

double _sumTipAmount(List<TipTransaction> rows) {
  return rows.fold<double>(0, (sum, row) {
    final value = double.tryParse(row.amount) ?? 0;
    return sum + value;
  });
}

String _resolveCurrencySymbol(TipsStore tipsStore, List<TipTransaction> rows) {
  final overviewSymbol = tipsStore.overview?.activeCurrency.symbol.trim();
  if (overviewSymbol != null && overviewSymbol.isNotEmpty) {
    return overviewSymbol;
  }
  if (rows.isEmpty) return 'MCR';

  final symbol = rows.first.currency.symbol.trim();
  if (symbol.isNotEmpty) return symbol;
  return rows.first.currency.code.trim().isNotEmpty
      ? rows.first.currency.code
      : 'MCR';
}

double _resolveTipBalance(TipsStore tipsStore, List<TipTransaction> rows) {
  final active = tipsStore.overview?.activeCurrency;
  if (active != null) {
    final balance = tipsStore.overview?.findBalance(active.code)?.balance;
    final parsed = _parseAmount(balance);
    if (parsed != null) {
      return parsed;
    }
  }

  return _sumTipAmount(rows);
}

DateTime? _latestTipAt(List<TipTransaction> rows) {
  if (rows.isEmpty) return null;
  var latest = rows.first.createdAt;
  for (final row in rows.skip(1)) {
    if (row.createdAt.isAfter(latest)) {
      latest = row.createdAt;
    }
  }
  return latest;
}

double? _parseAmount(String? raw) {
  if (raw == null) return null;
  final normalized = raw.trim().replaceAll(',', '');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

String _formatTipRecency(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }

  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
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

String _formatAmount(double value) {
  var text = value.toStringAsFixed(3);
  text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  return text;
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
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 10,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
