import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/mining/presentation/widgets/hero/mining_second_ticker.dart';
import 'package:blocnet/features/mining/presentation/widgets/mining_expired_notice_card.dart';
import 'package:blocnet/features/mining/presentation/widgets/mining_hero_card.dart';
import 'package:blocnet/features/mining/presentation/widgets/mining_section_entry_card.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/shared/utils/format_number_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});

  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen> {
  String? _lastShownError;
  String? _lastShownForfeitNotice;
  String? _dismissedExpiredSessionId;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back to the app after hours away must not show a stale cycle
    // (F-55). Only while the Mine tab is on screen; a hidden tab catches up
    // through its own refreshes.
    _lifecycle = AppLifecycleListener(onResume: _onAppResumed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MiningStore>().refreshAll();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onAppResumed() {
    if (!mounted || !isMiningTabVisible(context)) return;
    context.read<MiningStore>().loadSnapshot(force: true);
  }

  /// A failed action, or a failed refresh while data is already on screen.
  /// A failed *first* load is shown inside the hero instead.
  String? _feedbackError(MiningStore store) {
    final action = store.actionError;
    if (action != null && action.isNotEmpty) return action;
    if (store.snapshot == null) return null;
    final refresh = store.snapshotError;
    return (refresh != null && refresh.isNotEmpty) ? refresh : null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MiningStore>(
      builder: (context, store, _) {
        final error = _feedbackError(store);
        if (error == null) {
          _lastShownError = null;
        } else if (error != _lastShownError) {
          _lastShownError = error;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showFeedback(error, tone: _FeedbackTone.error);
          });
        }

        // A forfeited cycle is an outcome, not a crash: it gets its own
        // warning-styled message rather than the red error treatment.
        final forfeitNotice = store.forfeitNotice;
        if (forfeitNotice == null || forfeitNotice.isEmpty) {
          _lastShownForfeitNotice = null;
        } else if (forfeitNotice != _lastShownForfeitNotice) {
          // Guard against the several rebuilds `refreshAll` triggers before
          // the frame callback lands, so the notice is shown exactly once.
          _lastShownForfeitNotice = forfeitNotice;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showFeedback(forfeitNotice, tone: _FeedbackTone.warning);
            store.clearForfeitNotice();
          });
        }

        final expiredCycle = store.snapshot?.lastExpiredCycle;
        final showExpiredNotice =
            MiningExpiredNoticeCard.isCurrent(store.snapshot) &&
                expiredCycle?.sessionId != _dismissedExpiredSessionId;

        return RefreshIndicator(
          color: AppColors.primary500,
          backgroundColor: AppColors.bgSurface,
          onRefresh: store.refreshAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.lg, AppSpace.lg, 110),
            children: [
              const SizedBox(height: AppSpace.xs),
              MiningHeroCard(
                snapshot: store.snapshot,
                onStart: () => _onStart(store),
                onClaim: () => _onClaim(store),
                isStarting: store.isStarting,
                isClaiming: store.isClaiming,
                isLoadingSnapshot: store.isLoadingSnapshot,
                serverNow: store.serverNow,
                loadError: store.snapshotError,
                onRetry: () => store.loadSnapshot(force: true),
                onCycleEnd: store.refreshAtCycleEnd,
              ),
              if (showExpiredNotice && expiredCycle != null) ...[
                const SizedBox(height: AppSpace.md),
                MiningExpiredNoticeCard(
                  cycle: expiredCycle,
                  claimWindowHours:
                      store.snapshot?.config.claimWindowHours ?? 48,
                  onDismiss: () => setState(() {
                    _dismissedExpiredSessionId = expiredCycle.sessionId;
                  }),
                ),
              ],
              const SizedBox(height: AppSpace.md),
              MiningSectionEntryCard(
                icon: Icons.leaderboard_rounded,
                title: 'Mining Leaderboard',
                subtitle: _leaderboardSubtitle(store),
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.miningLeaderboard),
              ),
              Divider(
                height: 1,
                color: AppColors.borderSubtle.withValues(alpha: 0.8),
              ),
              const SizedBox(height: AppSpace.xs),
              MiningSectionEntryCard(
                icon: Icons.schedule_rounded,
                title: 'Hourly Mining History',
                subtitle: store.isLoadingSnapshot
                    ? 'Loading checkpoints...'
                    : '${formatGroupedNumber(store.snapshot?.hourlyHistory.length ?? 0, maxDecimals: 0)} checkpoints recorded',
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.miningHourlyHistory),
              ),
            ],
          ),
        );
      },
    );
  }

  String _leaderboardSubtitle(MiningStore store) {
    if (store.isLoadingLeaderboard) return 'Loading rankings...';
    if (store.leaderboard.isEmpty && store.leaderboardError != null) {
      return "Couldn't load rankings";
    }
    return '${formatGroupedNumber(store.leaderboard.length, maxDecimals: 0)} ranked miners';
  }

  Future<void> _onStart(MiningStore store) async {
    try {
      final result = await store.startMining();
      if (!mounted || result == null) return;
      // A start that also forfeited older cycles already set the store's
      // forfeit notice, which the builder surfaces on its own. An unreadable
      // body is not a start: the refresh shows what really happened.
      if (result.hasExpiredCycles || !result.isStarted) return;
      _showFeedback('Mining cycle started.');
    } catch (_) {
      // surfaced via store.actionError
    }
  }

  Future<void> _onClaim(MiningStore store) async {
    final walletStore = context.read<WalletStore>();
    try {
      final result = await store.claimMining();
      if (result == null) return;

      // The response body — not the absence of an exception — decides whether
      // anything was actually paid out. A forfeit is surfaced by the builder
      // via store.forfeitNotice.
      if (!result.isClaimed) return;

      try {
        await walletStore.refreshAll();
      } catch (_) {
        // Wallet refresh is best-effort; the claim itself already succeeded.
      }
      if (!mounted) return;
      final claimed = result.claimedPoints;
      final nextCycle =
          result.startedNextCycle ? ' New mining session started.' : '';
      final message = claimed > 0
          ? 'Claimed ${formatGroupedNumber(claimed, maxDecimals: 0)} BNP.$nextCycle'
          : 'Rewards claimed.$nextCycle';
      _showFeedback(message.trim());
    } catch (_) {
      // surfaced via store.actionError
    }
  }

  void _showFeedback(
    String message, {
    _FeedbackTone tone = _FeedbackTone.success,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.custom(
            size: AppText.labelSize,
            weight: FontWeight.w600,
            color: tone == _FeedbackTone.error
                ? AppColors.darkGrey900
                : Colors.black,
          ),
        ),
        backgroundColor: switch (tone) {
          _FeedbackTone.error => AppColors.error500,
          _FeedbackTone.warning => AppColors.warning500,
          _FeedbackTone.success => AppColors.successColor,
        },
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.mdValue),
        ),
        duration: Duration(
          seconds: tone == _FeedbackTone.warning ? 6 : 2,
        ),
      ),
    );
  }
}

/// Success, a forfeited cycle, and a genuine failure are three different
/// things and must not look alike.
enum _FeedbackTone { success, warning, error }
