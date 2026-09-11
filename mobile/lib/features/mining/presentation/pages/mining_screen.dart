import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
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
      await store.startMining();
      if (!mounted) return;
      _showFeedback('Mining cycle started.');
    } catch (_) {
      // surfaced via store.lastError
    }
  }

  Future<void> _onClaim(MiningStore store) async {
    final pointsBefore = store.snapshot?.balance.claimedTotalPoints ?? 0;
    final walletStore = context.read<WalletStore>();
    try {
      await store.claimMining();
      final pointsAfter = store.snapshot?.balance.claimedTotalPoints ?? 0;
      final claimedNow = (pointsAfter - pointsBefore).clamp(0, 1 << 31);
      try {
        await walletStore.refreshAll();
      } catch (_) {
        // Wallet refresh is best-effort; mining claim already succeeded.
      }
      if (!mounted) return;
      final message = claimedNow > 0
          ? 'Claimed ${formatGroupedNumber(claimedNow, maxDecimals: 0)} BNP. New mining session started.'
          : 'Rewards claimed. New mining session started.';
      _showFeedback(message);
    } catch (_) {
      // surfaced via store.lastError
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.custom(
            size: AppText.labelSize,
            weight: FontWeight.w600,
            color: isError ? AppColors.darkGrey900 : Colors.black,
          ),
        ),
        backgroundColor: isError ? AppColors.error500 : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.mdValue),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

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
