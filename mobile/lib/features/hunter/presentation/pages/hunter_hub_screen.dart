import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hunter_stats_grid.dart';
import 'package:blocnet/features/hunter/presentation/widgets/managed_projects_row.dart';
import 'package:blocnet/features/hunter/presentation/widgets/season_leaderboard.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

class HunterHubScreen extends StatelessWidget {
  const HunterHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final updates = context.watch<UpdatesStore>().updates;
    final userId = auth.userId ?? '';
    final username = auth.username ?? auth.displayName ?? '';
    final hunterUpdates = updates
        .where(
          (update) => _belongsToCurrentHunter(
            update: update,
            userId: userId,
            username: username,
          ),
        )
        .toList();

    final qualitySignals = hunterUpdates.where((update) {
      final label = update.priority.label.toLowerCase();
      return label == 'high' || label == 'mid' || label == 'medium';
    }).length;
    final successRate = hunterUpdates.isEmpty
        ? 0
        : ((qualitySignals / hunterUpdates.length) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: RefreshIndicator(
        color: AppColors.primary500,
        backgroundColor: AppColors.bgSurface,
        onRefresh: () async {
          final projectsStore = context.read<ProjectsStore>();
          final updatesStore = context.read<UpdatesStore>();
          await Future.wait([
            projectsStore.refreshProjects(),
            updatesStore.refreshUpdates(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const HunterStatsGrid(),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Manage My Projects'),
                  const SizedBox(height: 12),
                  const ManagedProjectsRow(),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Season Ranking'),
                  const SizedBox(height: 12),
                  const SeasonLeaderboard(),
                  const SizedBox(height: 24),
                  _EliteHunterBanner(successRate: successRate),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.custom(
        color: AppColors.textPrimary,
        size: 15,
        weight: FontWeight.w700,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Elite hunter promotional banner
// ─────────────────────────────────────────────────────────────────────────────

class _EliteHunterBanner extends StatelessWidget {
  const _EliteHunterBanner({required this.successRate});

  final int successRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary500.withValues(alpha: 0.12),
            AppColors.primary500.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.verified_rounded,
              color: AppColors.primary400,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elite Hunter Status',
                  style: AppTypography.custom(
                    color: AppColors.primary400,
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Maintain 85%+ success rate to keep Elite status',
                  style: AppTypography.custom(color: AppColors.textMuted,
                    size: 11,
                    weight: FontWeight.w400,
                    height: 1.4,),
                ),
                const SizedBox(height: 2),
                Text(
                  'Current quality rate: $successRate%',
                  style: AppTypography.custom(color: AppColors.textFaint,
                    size: 10,
                    weight: FontWeight.w400,),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.primary400.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

bool _belongsToCurrentHunter({
  required Update update,
  required String userId,
  required String username,
}) {
  if (userId.isNotEmpty &&
      (update.adminId == userId || update.admin?.id == userId)) {
    return true;
  }

  final normalizedCurrent = _normalizeHunterIdentity(username);
  if (normalizedCurrent.isEmpty) return false;

  final normalizedUpdate = _normalizeHunterIdentity(
    update.admin?.username ?? update.admin?.name ?? '',
  );
  return normalizedUpdate == normalizedCurrent;
}

String _normalizeHunterIdentity(String value) {
  return value.replaceAll('@', '').trim().toLowerCase();
}
