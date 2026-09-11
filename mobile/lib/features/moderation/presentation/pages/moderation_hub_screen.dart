import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/moderation/presentation/pages/appeals_queue_screen.dart';
import 'package:blocnet/features/moderation/presentation/pages/reports_queue_screen.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModerationHubScreen extends StatefulWidget {
  const ModerationHubScreen({super.key});

  @override
  State<ModerationHubScreen> createState() => _ModerationHubScreenState();
}

class _ModerationHubScreenState extends State<ModerationHubScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoadingStats = false;
  int _pendingReports = 0;
  int _pendingAppeals = 0;
  int _activeRestrictions = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (_isLoadingStats) return;
    setState(() => _isLoadingStats = true);

    try {
      final stats = await _apiClient.get('/community/moderation/stats');

      if (!mounted) return;
      setState(() {
        _pendingReports = (stats['pendingReports'] as num?)?.toInt() ?? 0;
        _pendingAppeals = (stats['pendingAppeals'] as num?)?.toInt() ?? 0;
        _activeRestrictions = (stats['activeRestrictions'] as num?)?.toInt() ?? 0;
      });
    } catch (e) {
      if (!mounted) return;
      // Silently fail - stats will show 0
      debugPrint('Failed to load moderation stats: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.primary400,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Text(
              'Moderation Hub',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: AppText.headlineSize,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              'Manage community content and user safety',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.bodySize,
                weight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppSpace.xl),

            // Stats overview
            _StatsOverviewSection(
              isLoading: _isLoadingStats,
              pendingReports: _pendingReports,
              pendingAppeals: _pendingAppeals,
              activeRestrictions: _activeRestrictions,
            ),
            const SizedBox(height: AppSpace.xl),

            // Quick actions grid
            Text(
              'Quick Actions',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: AppText.subtitleSize,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            _QuickActionsGrid(
              onReportsQueueTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReportsQueueScreen(),
                  ),
                );
              },
              onAppealsQueueTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AppealsQueueScreen(),
                  ),
                );
              },
              pendingReports: _pendingReports,
              pendingAppeals: _pendingAppeals,
            ),
            const SizedBox(height: AppSpace.xl),

            // Overview info card
            _OverviewInfoCard(),
          ],
        ),
      ),
    );
  }
}

class _StatsOverviewSection extends StatelessWidget {
  const _StatsOverviewSection({
    required this.isLoading,
    required this.pendingReports,
    required this.pendingAppeals,
    required this.activeRestrictions,
  });

  final bool isLoading;
  final int pendingReports;
  final int pendingAppeals;
  final int activeRestrictions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.flag_outlined,
            label: 'Pending\nReports',
            value: isLoading ? '...' : '$pendingReports',
            color: AppColors.error500,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: _StatCard(
            icon: Icons.replay_outlined,
            label: 'Pending\nAppeals',
            value: isLoading ? '...' : '$pendingAppeals',
            color: AppColors.warning500,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: _StatCard(
            icon: Icons.block_outlined,
            label: 'Active\nRestrictions',
            value: isLoading ? '...' : '$activeRestrictions',
            color: AppColors.teal400,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.mdValue),
            ),
            child: Center(
              child: Icon(icon, size: AppIcon.sm, color: color),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            value,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.titleSize,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpace.hair),
          Text(
            label,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.captionSize,
              weight: FontWeight.w500,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onReportsQueueTap,
    required this.onAppealsQueueTap,
    required this.pendingReports,
    required this.pendingAppeals,
  });

  final VoidCallback onReportsQueueTap;
  final VoidCallback onAppealsQueueTap;
  final int pendingReports;
  final int pendingAppeals;

  @override
  Widget build(BuildContext context) {
    // Only actions that exist today: reports and appeals. User Actions and
    // History return once a mobile client for them ships.
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: Icons.flag_rounded,
            label: 'Reports Queue',
            badge: pendingReports > 0 ? '$pendingReports' : null,
            color: AppColors.error500,
            onTap: () {
              HapticFeedback.selectionClick();
              onReportsQueueTap();
            },
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.replay_rounded,
            label: 'Appeals',
            badge: pendingAppeals > 0 ? '$pendingAppeals' : null,
            color: AppColors.warning500,
            onTap: () {
              HapticFeedback.selectionClick();
              onAppealsQueueTap();
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgSurface,
              AppColors.bgSurface.withValues(alpha: 0.88),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lgValue),
          border: Border.all(
            color: AppColors.borderSubtle.withValues(alpha: 0.75),
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.mdValue),
                  ),
                  child: Center(
                    child: Icon(icon, size: AppIcon.md, color: color),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  label,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: AppText.labelSize,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.hair),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.fullValue),
                  ),
                  child: Text(
                    badge!,
                    style: AppTypography.custom(
                      color: Colors.black,
                      size: AppText.captionSize,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverviewInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary400.withValues(alpha: 0.08),
            AppColors.teal400.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(
          color: AppColors.primary400.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary400.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.mdValue),
            ),
            child: Center(
              child: Icon(
                Icons.info_outline_rounded,
                size: AppIcon.md,
                color: AppColors.primary400,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moderation Guidelines',
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: AppText.labelSize,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Review reports promptly, apply consistent standards, and document decisions clearly. Appeals are reviewed by community admins.',
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: AppText.captionSize,
                    weight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
