import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/wallet/presentation/pages/wallet_transactions_screen.dart';
import 'package:blocnet/features/wallet/presentation/widgets/assets_section.dart';
import 'package:blocnet/features/wallet/presentation/widgets/balance_card.dart';
import 'package:blocnet/features/wallet/presentation/widgets/disclaimer_text.dart';
import 'package:blocnet/features/wallet/presentation/widgets/quick_actions.dart';
import 'package:blocnet/features/wallet/presentation/widgets/section_header.dart';
import 'package:blocnet/features/wallet/presentation/widgets/transactions_list.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_onboarding_banner.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Wallet tab: balance headline, Receive / Send, assets, recent activity.
class WalletScreen extends StatefulWidget {
  const WalletScreen({
    super.key,
    this.showTransactionsOnly = false,
  });

  /// The "View all" route reuses this widget to show the full activity list.
  final bool showTransactionsOnly;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _showWalletOnboardingBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final walletStore = context.read<WalletStore>();
      walletStore.loadWalletSummary(force: true);
      walletStore.loadTransactions(force: true);
      walletStore.loadWithdrawals(force: true);
      _resolveWalletOnboardingBanner();
    });
  }

  String? _bannerKey() {
    final userId = context.read<AuthStore>().userId?.trim();
    if (userId == null || userId.isEmpty) return null;
    return context.read<WalletStore>().walletOnboardingSeenKeyForUser(userId);
  }

  Future<void> _resolveWalletOnboardingBanner() async {
    final key = _bannerKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(key) == true;
    if (!mounted) return;
    setState(() => _showWalletOnboardingBanner = !seen);
  }

  Future<void> _dismissWalletOnboardingBanner() async {
    final key = _bannerKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
    if (!mounted) return;
    setState(() => _showWalletOnboardingBanner = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showTransactionsOnly) return const WalletTransactionsScreen();

    final walletStore = context.watch<WalletStore>();
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: RefreshIndicator(
        color: AppColors.primary500,
        backgroundColor: AppColors.bgSurface,
        onRefresh: walletStore.refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.lg,
            AppSpace.lg,
            AppSpace.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BalanceCard(),
              const SizedBox(height: AppSpace.md),
              const QuickActions(),
              if (_showWalletOnboardingBanner) ...[
                const SizedBox(height: AppSpace.md),
                WalletOnboardingBanner(
                  onDismiss: _dismissWalletOnboardingBanner,
                ),
              ],
              const SizedBox(height: AppSpace.xl),
              const SectionHeader(
                icon: Icons.token_outlined,
                label: 'Assets',
              ),
              const SizedBox(height: AppSpace.sm),
              const AssetsSection(),
              const SizedBox(height: AppSpace.xl),
              const SectionHeader(
                icon: Icons.receipt_long_outlined,
                label: 'Recent activity',
                actionLabel: 'View all',
                actionRoute: AppRoutes.walletTransactions,
              ),
              const SizedBox(height: AppSpace.sm),
              const TransactionsList(limit: 6),
              const SizedBox(height: AppSpace.xl),
              const DisclaimerText(),
            ],
          ),
        ),
      ),
    );
  }
}
