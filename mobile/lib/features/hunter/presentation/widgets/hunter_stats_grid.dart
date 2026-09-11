import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/hunter/presentation/widgets/tips_load_error_row.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/engagement/tips_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

/// 3-cell stats grid shown at the top of the Hunter Hub.
/// Displays received-tip stats + update performance + followers.
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
    final receivedSummary = _resolveReceivedSummary(tipsStore);
    final totalTipsReceived =
        _resolveTotalTipsReceived(receivedSummary, receivedHistory);
    final tipsCurrencySymbol = _resolveCurrencySymbol(
      tipsStore: tipsStore,
      summary: receivedSummary,
      rows: receivedHistory,
    );
    final tipBalance = totalTipsReceived;
    final totalTipsCount =
        receivedSummary?.transactionCount ?? tipsStore.receivedHistoryTotal;
    final latestTipAt = _latestTipAt(receivedHistory);

    return Column(
      children: [
        _TipsCard(
          isLoading:
              tipsStore.isLoadingReceivedHistory && receivedHistory.isEmpty,
          tipBalance: tipBalance,
          totalTipsReceived: totalTipsReceived,
          totalTipsCount: totalTipsCount,
          currencySymbol: tipsCurrencySymbol,
          latestTipAt: latestTipAt,
          lastError: tipsStore.lastError,
          onRetry: () => Future.wait([
            tipsStore.loadOverview(force: true),
            tipsStore.loadReceivedHistory(force: true, limit: 100),
          ]),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Success Rate',
                value: hunterUpdates.isEmpty ? '--' : '$successRate%',
                icon: Icons.track_changes_rounded,
                iconColor: hunterUpdates.isEmpty
                    ? AppColors.textMuted
                    : AppColors.successColor,
                trend: hunterUpdates.isEmpty
                    ? 'No updates yet'
                    : '$qualitySignals/${hunterUpdates.length} quality signals',
                // No data is not a failure: render neutral, not red.
                trendTone: hunterUpdates.isEmpty
                    ? _TrendTone.neutral
                    : (successRate >= 50
                        ? _TrendTone.positive
                        : _TrendTone.negative),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: _StatCard(
                label: 'Followers',
                value: _formatCompact(followers),
                icon: Icons.people_outline_rounded,
                iconColor: AppColors.primary400,
                trend: '$updatesThisWeek updates this week',
                trendTone: updatesThisWeek == 0
                    ? _TrendTone.neutral
                    : _TrendTone.positive,
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
    required this.onRetry,
  });

  final bool isLoading;
  final double tipBalance;
  final double totalTipsReceived;
  final int totalTipsCount;
  final String currencySymbol;
  final DateTime? latestTipAt;
  final String? lastError;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final symbol = currencySymbol.trim().isEmpty ? 'BNP' : currencySymbol;

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
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
                  borderRadius: BorderRadius.circular(AppRadius.mdValue),
                ),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  size: AppIcon.sm,
                  color: AppColors.primary400,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                'Tip Balance',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: AppText.labelSize,
                  weight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.hair),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xlValue),
                ),
                child: Text(
                  '$totalTipsCount tx',
                  style: AppTypography.custom(
                    color: AppColors.successColor,
                    size: AppText.captionSize,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
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
                    size: AppText.displaySize,
                    weight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.hair),
                  child: Text(
                    symbol,
                    style: AppTypography.custom(
                      color: AppColors.primary400,
                      size: AppText.labelSize,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpace.hair),
          Text(
            'Total received ${_formatAmount(totalTipsReceived)} $symbol from $totalTipsCount tips',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: AppSpace.hair),
          Text(
            latestTipAt == null
                ? 'No tips received yet'
                : 'Last tip ${_formatTipRecency(latestTipAt!)}',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w400,
            ),
          ),
          if (!isLoading &&
              totalTipsCount == 0 &&
              (lastError?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSpace.sm),
            TipsLoadErrorRow(onRetry: onRetry, compact: true),
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

TipReceivedSummary? _resolveReceivedSummary(TipsStore tipsStore) {
  final overview = tipsStore.overview;
  if (overview == null) return null;

  final activeCode = overview.activeCurrency.code.trim().toUpperCase();
  for (final summary in overview.receivedSummaryByCurrency) {
    if (summary.currency.code.trim().toUpperCase() == activeCode) {
      return summary;
    }
  }
  return overview.receivedSummary;
}

double _resolveTotalTipsReceived(
  TipReceivedSummary? summary,
  List<TipTransaction> rows,
) {
  final parsed = _parseAmount(summary?.amount);
  if (parsed != null) return parsed;
  return _sumTipAmount(rows);
}

String _resolveCurrencySymbol({
  required TipsStore tipsStore,
  required TipReceivedSummary? summary,
  required List<TipTransaction> rows,
}) {
  final summarySymbol = summary?.currency.symbol.trim();
  if (summarySymbol != null && summarySymbol.isNotEmpty) {
    return summarySymbol;
  }

  final overviewSymbol = tipsStore.overview?.activeCurrency.symbol.trim();
  if (overviewSymbol != null && overviewSymbol.isNotEmpty) {
    return overviewSymbol;
  }

  if (rows.isEmpty) return 'BNP';

  final symbol = rows.first.currency.symbol.trim();
  if (symbol.isNotEmpty) return symbol;
  return rows.first.currency.code.trim().isNotEmpty
      ? rows.first.currency.code
      : 'BNP';
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

enum _TrendTone { positive, negative, neutral }

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.trend,
    required this.trendTone,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String trend;
  final _TrendTone trendTone;

  @override
  Widget build(BuildContext context) {
    final trendColor = switch (trendTone) {
      _TrendTone.positive => AppColors.successColor,
      _TrendTone.negative => AppColors.error500,
      _TrendTone.neutral => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppIcon.sm, color: iconColor),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.hair),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.mdValue),
                ),
                child: Text(
                  trend,
                  style: AppTypography.custom(
                    color: trendColor,
                    size: AppText.captionSize,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            value,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.titleSize,
              weight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpace.hair),
          Text(
            label,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.captionSize,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
