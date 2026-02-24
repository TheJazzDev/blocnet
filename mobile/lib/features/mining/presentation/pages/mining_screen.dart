import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/mining/presentation/widgets/mining_hero_card.dart';
import 'package:blocnet/features/mining/presentation/widgets/referral_code_card.dart';
import 'package:blocnet/services/mining_store.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              const SizedBox(height: 5),
              MiningHeroCard(
                snapshot: store.snapshot,
                onStart: () => _onStart(store),
                onClaim: () => _onClaim(store),
                isStarting: store.isStarting,
                isClaiming: store.isClaiming,
              ),
              const SizedBox(height: 20),
              ReferralCodeCard(
                snapshot: store.snapshot,
                onCopy: _onCopyCode,
                onBind: () => _showBindSheet(store),
                isBinding: store.isBindingReferral,
              ),
              const SizedBox(height: 20),
              _MiningSectionEntryCard(
                icon: Icons.leaderboard_rounded,
                title: 'Mining Leaderboard',
                subtitle: store.isLoadingLeaderboard
                    ? 'Loading rankings...'
                    : '${store.leaderboard.length} ranked miners',
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.miningLeaderboard),
              ),
              const SizedBox(height: 20),
              _MiningSectionEntryCard(
                icon: Icons.schedule_rounded,
                title: 'Hourly Mining History',
                subtitle: store.isLoadingSnapshot
                    ? 'Loading checkpoints...'
                    : '${store.snapshot?.hourlyHistory.length ?? 0} checkpoints recorded',
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.miningHourlyHistory),
              ),
              const SizedBox(height: 20),
              _MiningSectionEntryCard(
                icon: Icons.group_rounded,
                title: 'Referral Downline',
                subtitle: store.isLoadingDownline
                    ? 'Loading referrals...'
                    : '${store.downline.length} members in your network',
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.miningDownline,
                ),
              ),
              const SizedBox(height: 12),
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
          ? 'Claimed $claimedNow points. New mining session started.'
          : 'Rewards claimed. New mining session started.';
      _showFeedback(message);
    } catch (_) {
      // surfaced via store.lastError
    }
  }

  Future<void> _onCopyCode() async {
    final code = context.read<MiningStore>().snapshot?.referral.code;
    if (code == null || code.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    _showFeedback('Referral code copied.');
  }

  Future<void> _showBindSheet(MiningStore store) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    String? error;
    bool validating = false;
    bool binding = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> submit() async {
              final code = controller.text.trim().toUpperCase();
              if (code.length != 8) {
                setLocalState(
                    () => error = 'Referral code must be 8 characters.');
                return;
              }

              setLocalState(() {
                error = null;
                validating = true;
              });

              final validation = await store.validateReferralCode(code);
              if (!mounted) return;

              if (validation == null || !validation.valid) {
                setLocalState(() {
                  validating = false;
                  error = 'Referral code is invalid.';
                });
                return;
              }

              setLocalState(() {
                validating = false;
                binding = true;
              });

              try {
                await store.bindReferralCode(code);
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Referral code bound successfully.'),
                    backgroundColor: AppColors.successColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (_) {
                if (!mounted) return;
                setLocalState(() {
                  binding = false;
                  error = store.lastError ?? 'Failed to bind referral code.';
                });
              }
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderMuted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bind Referral Code',
                      style: AppTypography.custom(
                        size: 18,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      maxLength: 8,
                      textCapitalization: TextCapitalization.characters,
                      style: AppTypography.custom(
                        size: 14,
                        weight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter 8-character code',
                        counterText: '',
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: AppTypography.custom(
                          size: 12,
                          weight: FontWeight.w400,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: validating || binding ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          foregroundColor: Colors.black,
                        ),
                        child: validating || binding
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Bind Code',
                                style: AppTypography.custom(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFeedback(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.custom(
            size: 12,
            weight: FontWeight.w600,
            color: isError ? AppColors.darkGrey900 : Colors.black,
          ),
        ),
        backgroundColor: isError ? AppColors.error500 : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary500.withValues(alpha: 0.12),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: AppColors.primary400,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 13,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 11,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textFaint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
