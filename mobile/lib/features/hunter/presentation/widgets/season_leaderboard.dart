import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

/// Season leaderboard mini widget for Hunter Hub.
/// Shows rank #1, current user's rank, and the rank just below.
class SeasonLeaderboard extends StatelessWidget {
  const SeasonLeaderboard({super.key});

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
            fallback: adminId == currentUserId ? currentUsername : null,
          ),
          tips: _scoreUpdate(update),
        );
      } else {
        scores[adminId] = existing.copyWith(
          username: _resolveUsername(
            update,
            fallback: existing.username,
          ),
          tips: existing.tips + _scoreUpdate(update),
        );
      }
    }

    final ranked = scores.values.toList()
      ..sort((a, b) {
        final byTips = b.tips.compareTo(a.tips);
        if (byTips != 0) return byTips;
        return a.username.compareTo(b.username);
      });

    final entries = ranked
        .asMap()
        .entries
        .map(
          (entry) => _LeaderboardEntry(
            rank: entry.key + 1,
            username: entry.value.username,
            tips: entry.value.tips,
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
      tips: 0,
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
          // Header
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
                const Spacer(),
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
        ],
      ),
    );
  }
}

class _LeaderboardScore {
  const _LeaderboardScore({
    required this.adminId,
    required this.username,
    required this.tips,
  });

  final String adminId;
  final String username;
  final int tips;

  _LeaderboardScore copyWith({
    String? username,
    int? tips,
  }) {
    return _LeaderboardScore(
      adminId: adminId,
      username: username ?? this.username,
      tips: tips ?? this.tips,
    );
  }
}

class _LeaderboardEntry {
  const _LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.tips,
    required this.isCurrentUser,
  });

  final int rank;
  final String username;
  final int tips;
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
          // Rank badge
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: AppTypography.custom(
                color: rankColor,
                size: 13,
                weight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar placeholder
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: entry.isCurrentUser
                  ? AppColors.primary500.withValues(alpha: 0.15)
                  : AppColors.bgElevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: entry.isCurrentUser
                    ? AppColors.primary500.withValues(alpha: 0.4)
                    : AppColors.borderSubtle,
              ),
            ),
            child: Center(
              child: Text(
                entry.username.isNotEmpty
                    ? entry.username[0].toUpperCase()
                    : '?',
                style: AppTypography.custom(
                  color: entry.isCurrentUser
                      ? AppColors.primary400
                      : AppColors.textMuted,
                  size: 11,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isCurrentUser
                      ? 'You (${entry.username})'
                      : entry.username,
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
              ],
            ),
          ),
          // Tips
          Text(
            '${_formatTips(entry.tips)} \$BNT',
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

  String _formatTips(int tips) {
    if (tips >= 1000) {
      return '${(tips / 1000).toStringAsFixed(1)}k';
    }
    return tips.toString();
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

  return '@hunter';
}

String _formatUsername(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '@hunter';
  return trimmed.startsWith('@') ? trimmed : '@$trimmed';
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

int _scoreUpdate(Update update) {
  final label = update.priority.label.toLowerCase();
  final base = label == 'high'
      ? 120
      : (label == 'mid' || label == 'medium')
          ? 70
          : 35;
  final reachBoost = ((update.project?.followersCount ?? 0) / 25).floor();
  return base + reachBoost;
}
