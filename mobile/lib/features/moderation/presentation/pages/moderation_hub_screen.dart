import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/moderation/presentation/pages/appeals_queue_screen.dart';
import 'package:blocnet/features/moderation/presentation/pages/inactive_gems_queue_screen.dart';
import 'package:blocnet/features/moderation/presentation/pages/reports_queue_screen.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_styles.dart';
import 'package:blocnet/features/moderation/presentation/widgets/hub/mod_hub_panels.dart';
import 'package:blocnet/features/moderation/presentation/widgets/hub/mod_hub_queues_card.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// The moderation space's home tab: the three queues with their waiting
/// counts, active restrictions, and the house rules. Each number appears
/// once; a failed load shows an error, never zeros.
class ModerationHubScreen extends StatefulWidget {
  const ModerationHubScreen({this.apiClient, super.key});

  /// Injectable for tests.
  final ApiClient? apiClient;

  @override
  State<ModerationHubScreen> createState() => _ModerationHubScreenState();
}

class _ModerationHubStats {
  const _ModerationHubStats({
    required this.reports,
    required this.appeals,
    required this.restrictions,
    required this.inactiveGems,
  });

  factory _ModerationHubStats.fromApi(dynamic json) {
    final map = json is Map ? json : const {};
    int read(String key) => (map[key] as num?)?.toInt() ?? 0;
    return _ModerationHubStats(
      reports: read('pendingReports'),
      appeals: read('pendingAppeals'),
      restrictions: read('activeRestrictions'),
      inactiveGems: read('openInactiveGems'),
    );
  }

  final int reports;
  final int appeals;
  final int restrictions;
  final int inactiveGems;
}

class _ModerationHubScreenState extends State<ModerationHubScreen> {
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();
  bool _isLoadingStats = false;

  /// Null while loading or after a failure: the counts are then unknown.
  _ModerationHubStats? _stats;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (_isLoadingStats) return;
    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });

    try {
      final json = await _apiClient.get('/community/moderation/stats');
      if (!mounted) return;
      setState(() => _stats = _ModerationHubStats.fromApi(json));
    } catch (e) {
      if (!mounted) return;
      debugPrint('Failed to load moderation stats: $e');
      setState(() {
        _stats = null;
        _statsError = describeApiError(
          e,
          fallback: 'Queue counts could not be loaded.',
        );
      });
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  /// Opens a queue and refreshes the counts on the way back, since the
  /// moderator has probably just changed them.
  Future<void> _openQueue(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
    if (mounted) _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    // The last good counts stay up during a refresh; a failure clears them.
    final stats = _stats;
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: ModTone.accent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          ModTone.gutter,
          0,
          ModTone.gutter,
          AppSpace.xxl,
        ),
        children: [
          if (_statsError != null && !_isLoadingStats) ...[
            AppSpace.gapLg,
            AppSurface.flush(
              child: AppEmptyState.error(
                compact: true,
                title: 'Queue counts did not load',
                message: _statsError,
                onAction: _loadStats,
              ),
            ),
          ],
          const ModHubHeader(label: 'Queues', icon: Icons.inbox_outlined),
          ModHubQueuesCard(queues: _queues(stats)),
          const ModHubHeader(label: 'Status', icon: Icons.shield_outlined),
          ModHubRestrictionsCard(count: stats?.restrictions),
          const ModHubHeader(
            label: 'Guidelines',
            icon: Icons.info_outline_rounded,
          ),
          const ModHubGuidelinesCard(),
        ],
      ),
    );
  }

  List<ModHubQueue> _queues(_ModerationHubStats? stats) {
    // Only queues that exist on mobile today. User Actions and History
    // return once a client for them ships.
    return [
      ModHubQueue(
        icon: Icons.flag_rounded,
        color: ModTone.accent,
        title: 'Reports',
        subtitle: 'Posts, comments and profiles',
        count: stats?.reports,
        onTap: () => _openQueue(ReportsQueueScreen(apiClient: widget.apiClient)),
      ),
      ModHubQueue(
        icon: Icons.replay_rounded,
        color: ModTone.open,
        title: 'Appeals',
        subtitle: 'Decisions members contest',
        count: stats?.appeals,
        onTap: () => _openQueue(AppealsQueueScreen(apiClient: widget.apiClient)),
      ),
      ModHubQueue(
        icon: Icons.hourglass_empty_rounded,
        color: AppColors.tagAirdrop,
        title: 'Quiet gems reported',
        subtitle: 'Gems members say went quiet',
        count: stats?.inactiveGems,
        onTap: () => _openQueue(
          InactiveGemsQueueScreen(apiClient: widget.apiClient),
        ),
      ),
    ];
  }
}
