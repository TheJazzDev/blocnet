import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

/// Season leaderboard mini widget for Hunter Hub.
/// Ranking is based on real published updates count.
class SeasonLeaderboard extends StatelessWidget {
  const SeasonLeaderboard({
    super.key,
    this.onViewFullLeaderboard,
  });

  final VoidCallback? onViewFullLeaderboard;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final updates = context.watch<UpdatesStore>().updates;
    final currentUserId = auth.userId ?? '';
    final currentUsername = auth.username ?? auth.displayName ?? 'You';

    final scores = <String, _LeaderboardScore>{};
    for (final update in updates) {
      final adminId =
          update.adminId.isNotEmpty ? update.adminId : (update.admin?.id ?? '');
      if (adminId.isEmpty) continue;

      final existing = scores[adminId];
      if (existing == null) {
        scores[adminId] = _LeaderboardScore(
          adminId: adminId,
          username: _resolveUsername(
            update,
            fallback: adminId == currentUserId
                ? currentUsername
                : _fallbackUsernameFromAdminId(adminId),
          ),
          updatesCount: 1,
          totalTipsReceived: update.admin?.totalTipsReceived ?? 0,
          lastUpdateAt: update.createdAt,
        );
      } else {
        final nextLastUpdate = update.createdAt.isAfter(existing.lastUpdateAt)
            ? update.createdAt
            : existing.lastUpdateAt;
        scores[adminId] = existing.copyWith(
          username: _resolveUsername(
            update,
            fallback: existing.username,
          ),
          updatesCount: existing.updatesCount + 1,
          totalTipsReceived: existing.totalTipsReceived >
                  (update.admin?.totalTipsReceived ?? 0)
              ? existing.totalTipsReceived
              : (update.admin?.totalTipsReceived ?? 0),
          lastUpdateAt: nextLastUpdate,
        );
      }
    }

    final ranked = scores.values.toList()
      ..sort((a, b) {
        final byUpdates = b.updatesCount.compareTo(a.updatesCount);
        if (byUpdates != 0) return byUpdates;
        final byLastUpdate = b.lastUpdateAt.compareTo(a.lastUpdateAt);
        if (byLastUpdate != 0) return byLastUpdate;
        return a.username.compareTo(b.username);
      });

    final entries = ranked
        .asMap()
        .entries
        .map(
          (entry) => _LeaderboardEntry(
            rank: entry.key + 1,
            username: entry.value.username,
            updatesCount: entry.value.updatesCount,
            totalTipsReceived: entry.value.totalTipsReceived,
            isCurrentUser: _isCurrentUser(
              adminId: entry.value.adminId,
              username: entry.value.username,
              currentUserId: currentUserId,
              currentUsername: currentUsername,
            ),
          ),
        )
        .toList();

    final currentEntryIndex =
        entries.indexWhere((entry) => entry.isCurrentUser);
    final fallbackCurrent = _LeaderboardEntry(
      rank: entries.length + 1,
      username: _formatUsername(currentUsername),
      updatesCount: 0,
      totalTipsReceived: 0,
      isCurrentUser: true,
    );

    final rows = <_LeaderboardEntry>[];
    void addRow(_LeaderboardEntry row) {
      final exists = rows.any(
        (item) => item.rank == row.rank && item.username == row.username,
      );
      if (!exists && rows.length < 3) {
        rows.add(row);
      }
    }

    if (entries.isNotEmpty) {
      addRow(entries.first);
    }

    if (currentEntryIndex != -1) {
      addRow(entries[currentEntryIndex]);
      final nextRank = currentEntryIndex + 1;
      if (nextRank < entries.length) {
        addRow(entries[nextRank]);
      }
    } else {
      addRow(fallbackCurrent);
    }

    for (final entry in entries) {
      if (rows.length >= 3) break;
      addRow(entry);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Text(
                  'RANK',
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 9,
                    weight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'USERNAME',
                    style: AppTypography.custom(
                      color: AppColors.textFaint,
                      size: 9,
                      weight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'UPDATES',
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 9,
                    weight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'TIPS',
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 9,
                    weight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            return Column(
              children: [
                _LeaderboardRow(entry: entry.value),
                if (!isLast) const Divider(height: 1),
              ],
            );
          }),
          const Divider(height: 1),
          InkWell(
            onTap: onViewFullLeaderboard ??
                () => Navigator.of(context).pushNamed(AppRoutes.topHunters),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Full Leaderboard',
                    style: AppTypography.custom(
                      color: AppColors.primary400,
                      size: 12,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: AppColors.primary400,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardScore {
  const _LeaderboardScore({
    required this.adminId,
    required this.username,
    required this.updatesCount,
    required this.totalTipsReceived,
    required this.lastUpdateAt,
  });

  final String adminId;
  final String username;
  final int updatesCount;
  final double totalTipsReceived;
  final DateTime lastUpdateAt;

  _LeaderboardScore copyWith({
    String? username,
    int? updatesCount,
    double? totalTipsReceived,
    DateTime? lastUpdateAt,
  }) {
    return _LeaderboardScore(
      adminId: adminId,
      username: username ?? this.username,
      updatesCount: updatesCount ?? this.updatesCount,
      totalTipsReceived: totalTipsReceived ?? this.totalTipsReceived,
      lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
    );
  }
}

class _LeaderboardEntry {
  const _LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.updatesCount,
    required this.totalTipsReceived,
    required this.isCurrentUser,
  });

  final int rank;
  final String username;
  final int updatesCount;
  final double totalTipsReceived;
  final bool isCurrentUser;
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});

  final _LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final rankColor = entry.rank == 1
        ? const Color(0xFFFFD700)
        : entry.isCurrentUser
            ? AppColors.primary400
            : AppColors.textMuted;

    return Container(
      color: entry.isCurrentUser
          ? AppColors.primary500.withValues(alpha: 0.06)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#${entry.rank}',
              style: AppTypography.custom(
                color: rankColor,
                size: 13,
                weight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.isCurrentUser ? 'You (${entry.username})' : entry.username,
              style: AppTypography.custom(
                color: entry.isCurrentUser
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                size: 12,
                weight: entry.isCurrentUser ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.updatesCount.toString(),
            style: AppTypography.custom(
              color: entry.isCurrentUser
                  ? AppColors.primary400
                  : AppColors.textSecondary,
              size: 12,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 18),
          Text(
            _formatTipsReceived(entry.totalTipsReceived),
            style: AppTypography.custom(
              color: entry.isCurrentUser
                  ? AppColors.primary400
                  : AppColors.textSecondary,
              size: 12,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _resolveUsername(
  Update update, {
  String? fallback,
}) {
  final username = update.admin?.username.trim() ?? '';
  if (username.isNotEmpty) {
    return _formatUsername(username);
  }

  final name = update.admin?.name.trim() ?? '';
  if (name.isNotEmpty) {
    return _formatUsername(name);
  }

  if (fallback != null && fallback.trim().isNotEmpty) {
    return _formatUsername(fallback);
  }

  return '@member';
}

String _formatUsername(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '@member';
  return trimmed.startsWith('@') ? trimmed : '@$trimmed';
}

String _fallbackUsernameFromAdminId(String adminId) {
  final compact = adminId.replaceAll('-', '').trim();
  if (compact.isEmpty) return '@member';
  final suffix = compact.length <= 6 ? compact : compact.substring(0, 6);
  return '@$suffix';
}

bool _isCurrentUser({
  required String adminId,
  required String username,
  required String currentUserId,
  required String currentUsername,
}) {
  if (currentUserId.isNotEmpty && adminId == currentUserId) {
    return true;
  }

  final normalizedEntry = username.replaceAll('@', '').toLowerCase();
  final normalizedCurrent = currentUsername.replaceAll('@', '').toLowerCase();
  return normalizedCurrent.isNotEmpty && normalizedEntry == normalizedCurrent;
}

String _formatTipsReceived(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}
