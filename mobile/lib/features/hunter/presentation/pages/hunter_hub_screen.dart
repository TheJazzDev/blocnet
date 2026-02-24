import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hunter_stats_grid.dart';
import 'package:blocnet/features/hunter/presentation/widgets/managed_projects_row.dart';
import 'package:blocnet/features/hunter/presentation/widgets/season_leaderboard.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/services/tips_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HunterHubScreen extends StatefulWidget {
  const HunterHubScreen({super.key});

  @override
  State<HunterHubScreen> createState() => _HunterHubScreenState();
}

class _HunterHubScreenState extends State<HunterHubScreen> {
  DateTime? _lastTipsSyncAt;
  bool _tipsSyncQueued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _primeInitialData();
    });
  }

  Future<void> _primeInitialData() async {
    final auth = context.read<AuthStore>();
    final projectsStore = context.read<ProjectsStore>();
    final updatesStore = context.read<UpdatesStore>();
    context.read<TipsStore>().ensureUserScope(auth.userId);
    await Future.wait([
      projectsStore.fetchProjectsOnce(),
      updatesStore.fetchUpdatesOnce(),
      _syncTips(force: true),
    ]);
  }

  Future<void> _syncTips({required bool force}) async {
    final tipsStore = context.read<TipsStore>();
    tipsStore.ensureUserScope(context.read<AuthStore>().userId);
    await Future.wait([
      tipsStore.loadOverview(force: force),
      tipsStore.loadReceivedHistory(force: force, limit: 100),
    ]);
    _lastTipsSyncAt = DateTime.now();
  }

  void _scheduleTipsSyncIfStale() {
    if (_tipsSyncQueued) return;
    final now = DateTime.now();
    final isFresh = _lastTipsSyncAt != null &&
        now.difference(_lastTipsSyncAt!).inSeconds < 45;
    if (isFresh) return;

    _tipsSyncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _tipsSyncQueued = false;
      if (!mounted) return;
      await _syncTips(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final updates = context.watch<UpdatesStore>().updates;
    final tipsStore = context.watch<TipsStore>();
    final userId = auth.userId ?? '';
    final username = auth.username ?? auth.displayName ?? '';

    _scheduleTipsSyncIfStale();

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
            _syncTips(force: true),
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
                  _SectionHeader(title: 'Recent Received Tips'),
                  const SizedBox(height: 12),
                  _RecentReceivedTipsCard(
                    isLoading: tipsStore.isLoadingReceivedHistory &&
                        tipsStore.receivedHistory.isEmpty,
                    rows: tipsStore.receivedHistory,
                    error: tipsStore.lastError,
                    onRetry: () => _syncTips(force: true),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Manage My Projects'),
                  const SizedBox(height: 12),
                  const ManagedProjectsRow(),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Season Ranking'),
                  const SizedBox(height: 12),
                  SeasonLeaderboard(
                    onViewFullLeaderboard: () =>
                        Navigator.of(context).pushNamed(AppRoutes.topHunters),
                  ),
                  const SizedBox(height: 24),
                  _EliteHunterBanner(successRate: successRate),
                  const SizedBox(height: 24),
                  const _CommunityBridgeLink(),
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

class _RecentReceivedTipsCard extends StatelessWidget {
  const _RecentReceivedTipsCard({
    required this.isLoading,
    required this.rows,
    required this.error,
    required this.onRetry,
  });

  final bool isLoading;
  final List<TipTransaction> rows;
  final String? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows.take(6).toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.primary500,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (visibleRows.isEmpty) ...[
            Text(
              error == null || error!.trim().isEmpty
                  ? 'No tips received yet.'
                  : 'Unable to load received tips.',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w500,
              ),
            ),
            if (error != null && error!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Tip sync warning: $error',
                style: AppTypography.custom(
                  color: AppColors.warning500,
                  size: 11,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: AppColors.bgElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Retry Sync',
                  style: AppTypography.custom(
                    color: AppColors.primary400,
                    size: 12,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ] else ...[
            ...visibleRows.map((row) => _RecentReceivedTipRow(row: row)),
          ],
        ],
      ),
    );
  }
}

class _RecentReceivedTipRow extends StatelessWidget {
  const _RecentReceivedTipRow({required this.row});

  final TipTransaction row;

  @override
  Widget build(BuildContext context) {
    final symbol = row.currency.symbol.trim().isEmpty
        ? row.currency.code
        : row.currency.symbol;
    final sender = _tipSenderLabel(row);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.successColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.south_west_rounded,
              color: AppColors.successColor,
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From $sender',
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 12,
                    weight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  row.note?.trim().isNotEmpty == true
                      ? row.note!.trim()
                      : _tipContextLabel(row),
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 10,
                    weight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${row.amount} $symbol',
                style: AppTypography.custom(
                  color: AppColors.successColor,
                  size: 12,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                _formatTipTimestamp(row.createdAt),
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
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
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 11,
                    weight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Current quality rate: $successRate%',
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 10,
                    weight: FontWeight.w400,
                  ),
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

String _tipSenderLabel(TipTransaction row) {
  final displayName = row.sender.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final username = row.sender.username?.trim();
  if (username != null && username.isNotEmpty) {
    return username.startsWith('@') ? username : '@$username';
  }

  return row.sender.id.isNotEmpty ? row.sender.id : 'User';
}

String _tipContextLabel(TipTransaction row) {
  final context = row.contextType?.trim();
  if (context == null || context.isEmpty) {
    return 'Tip received';
  }
  return context.replaceAll('_', ' ');
}

String _formatTipTimestamp(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day';
}

class _CommunityBridgeLink extends StatelessWidget {
  const _CommunityBridgeLink();

  void _navigateToCommunity(BuildContext context) async {
    final authStore = context.read<AuthStore>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('navigate_to_tab_after_switch', 2);
    await authStore.switchSpaceWithTransition('user');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToCommunity(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 18,
              color: AppColors.primary400,
            ),
            const SizedBox(width: 8),
            Text(
              'Discuss with the community',
              style: AppTypography.custom(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.primary400,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.primary400,
            ),
          ],
        ),
      ),
    );
  }
}
