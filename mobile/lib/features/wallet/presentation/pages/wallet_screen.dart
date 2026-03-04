import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
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

class WalletScreen extends StatefulWidget {
  const WalletScreen({
    super.key,
    this.showTransactionsOnly = false,
  });

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

  Future<void> _resolveWalletOnboardingBanner() async {
    final auth = context.read<AuthStore>();
    final walletStore = context.read<WalletStore>();
    final userId = auth.userId?.trim();
    if (userId == null || userId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = walletStore.walletOnboardingSeenKeyForUser(userId);
    final seen = prefs.getBool(key) == true;
    if (!mounted) return;

    setState(() => _showWalletOnboardingBanner = !seen);
  }

  Future<void> _dismissWalletOnboardingBanner() async {
    final auth = context.read<AuthStore>();
    final walletStore = context.read<WalletStore>();
    final userId = auth.userId?.trim();
    if (userId == null || userId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        walletStore.walletOnboardingSeenKeyForUser(userId), true);

    if (!mounted) return;
    setState(() => _showWalletOnboardingBanner = false);
  }

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    if (widget.showTransactionsOnly) {
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: AppBar(
          title: Text(
            'Transactions',
            style: AppTypography.custom(
              size: 18,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: RefreshIndicator(
          color: AppColors.primary500,
          backgroundColor: AppColors.bgSurface,
          onRefresh: walletStore.refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: TransactionsList(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: RefreshIndicator(
        color: AppColors.primary500,
        backgroundColor: AppColors.bgSurface,
        onRefresh: walletStore.refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const BalanceCard(),
                if (_showWalletOnboardingBanner) ...[
                  const SizedBox(height: 14),
                  WalletOnboardingBanner(
                    onDismiss: () {
                      _dismissWalletOnboardingBanner();
                    },
                  ),
                ],
                const SizedBox(height: 20),
                const QuickActions(),
                const SizedBox(height: 24),
                const SectionHeader(label: 'Assets'),
                const SizedBox(height: 10),
                const AssetsSection(),
                const SizedBox(height: 24),
                const SectionHeader(
                  label: 'Recent Activity',
                  actionLabel: 'View all',
                  actionRoute: AppRoutes.walletTransactions,
                ),
                const SizedBox(height: 8),
                const TransactionsList(limit: 6),
                const SizedBox(height: 16),
                const DisclaimerText(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
