import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/mining/presentation/widgets/mining_expired_notice_card.dart';
import 'package:blocnet/features/mining/presentation/widgets/mining_hero_card.dart';
import 'package:blocnet/shared/utils/format_number_utils.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MiningStore>().refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MiningStore>(
      builder: (context, store, _) {
        final error = store.lastError;
        if (error != null && error.isNotEmpty && error != _lastShownError) {
          _lastShownError = error;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showFeedback(error, isError: true);
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
              _MiningSectionEntryCard(
                icon: Icons.leaderboard_rounded,
                title: 'Mining Leaderboard',
                subtitle: store.isLoadingLeaderboard
                    ? 'Loading rankings...'
                    : '${formatGroupedNumber(store.leaderboard.length, maxDecimals: 0)} ranked miners',
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.miningLeaderboard),
              ),
              Divider(
                height: 1,
                color: AppColors.borderSubtle.withValues(alpha: 0.8),
              ),
              const SizedBox(height: AppSpace.xs),
              _MiningSectionEntryCard(
                icon: Icons.schedule_rounded,
                title: 'Hourly Mining History',
                subtitle: store.isLoadingSnapshot
                    ? 'Loading checkpoints...'
                    : '${formatGroupedNumber(store.snapshot?.hourlyHistory.length ?? 0, maxDecimals: 0)} checkpoints recorded',
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.miningHourlyHistory),
              ),
              const SizedBox(height: AppSpace.md),
              if (store.isLoadingSnapshot && store.snapshot == null)
                Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.primary500,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onStart(MiningStore store) async {
    try {
      final result = await store.startMining();
      if (!mounted) return;
      // A start that also forfeited older cycles already set the store's
      // forfeit notice, which the builder surfaces on its own.
      if (result != null && result.hasExpiredCycles) return;
      _showFeedback('Mining cycle started.');
    } catch (_) {
      // surfaced via store.lastError
    }
  }

  Future<void> _onClaim(MiningStore store) async {
    final walletStore = context.read<WalletStore>();
    try {
      final result = await store.claimMining();
      if (result == null) return;

      // The response body — not the absence of an exception — decides whether
      // anything was actually paid out.
      if (!result.isClaimed) {
        // The forfeit copy is surfaced by the builder via store.forfeitNotice.
        return;
      }

      try {
        await walletStore.refreshAll();
      } catch (_) {
        // Wallet refresh is best-effort; the claim itself already succeeded.
      }
      if (!mounted) return;
      final claimed = result.claimedPoints;
      final nextCycle = result.startedNextCycle
          ? ' New mining session started.'
          : '';
      final message = claimed > 0
          ? 'Claimed ${formatGroupedNumber(claimed, maxDecimals: 0)} BNP.$nextCycle'
          : 'Rewards claimed.$nextCycle';
      _showFeedback(message.trim());
    } catch (_) {
      // surfaced via store.lastError
    }
  }

  void _showFeedback(
    String message, {
    bool isError = false,
    _FeedbackTone? tone,
  }) {
    final resolved =
        tone ?? (isError ? _FeedbackTone.error : _FeedbackTone.success);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.custom(
            size: AppText.labelSize,
            weight: FontWeight.w600,
            color: resolved == _FeedbackTone.error
                ? AppColors.darkGrey900
                : Colors.black,
          ),
        ),
        backgroundColor: switch (resolved) {
          _FeedbackTone.error => AppColors.error500,
          _FeedbackTone.warning => AppColors.warning500,
          _FeedbackTone.success => AppColors.successColor,
        },
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.mdValue),
        ),
        duration: Duration(
          seconds: resolved == _FeedbackTone.warning ? 6 : 2,
        ),
      ),
    );
  }
}

/// Success, a forfeited cycle, and a genuine failure are three different
/// things and must not look alike.
enum _FeedbackTone { success, warning, error }

class _MiningSectionEntryCard extends StatelessWidget {
  const _MiningSectionEntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary400,
              size: AppIcon.md,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.labelSize,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: AppText.captionSize,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textFaint,
              size: AppIcon.md,
            ),
          ],
        ),
      ),
    );
  }
}
