import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

part 'wallet/wallet_screen_sections.part.dart';
part 'wallet/wallet_screen_actions.part.dart';
part 'wallet/wallet_screen_info.part.dart';

enum _WalletToastType { info, success, error }

void _showWalletToast(
  BuildContext context, {
  required String message,
  _WalletToastType type = _WalletToastType.info,
}) {
  final messenger = ScaffoldMessenger.of(context);

  Color backgroundColor;
  Color borderColor;
  IconData icon;

  switch (type) {
    case _WalletToastType.success:
      backgroundColor = const Color(0xFF0D2A22);
      borderColor = AppColors.successColor.withValues(alpha: 0.65);
      icon = Icons.check_circle_rounded;
      break;
    case _WalletToastType.error:
      backgroundColor = AppColors.error900.withValues(alpha: 0.95);
      borderColor = AppColors.error500.withValues(alpha: 0.75);
      icon = Icons.error_rounded;
      break;
    case _WalletToastType.info:
      backgroundColor = const Color(0xFF0B2A30);
      borderColor = AppColors.primary500.withValues(alpha: 0.55);
      icon = Icons.info_rounded;
      break;
  }

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 6),
      showCloseIcon: true,
      closeIconColor: AppColors.textMuted,
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      content: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.custom(
                size: 13,
                weight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

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
              child: _TransactionsList(),
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
                const _BalanceCard(),
                if (_showWalletOnboardingBanner) ...[
                  const SizedBox(height: 14),
                  _WalletOnboardingBanner(
                    onDismiss: () {
                      _dismissWalletOnboardingBanner();
                    },
                  ),
                ],
                const SizedBox(height: 20),
                const _QuickActions(),
                const SizedBox(height: 24),
                const _SectionHeader(label: 'Assets'),
                const SizedBox(height: 10),
                const _AssetsSection(),
                const SizedBox(height: 24),
                const _SectionHeader(
                  label: 'Recent Activity',
                  actionLabel: 'View all',
                  actionRoute: AppRoutes.walletTransactions,
                ),
                const SizedBox(height: 8),
                const _TransactionsList(limit: 6),
                const SizedBox(height: 16),
                const _DisclaimerText(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletOnboardingBanner extends StatelessWidget {
  const _WalletOnboardingBanner({
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.primary400,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet quick start',
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 12,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Use Receive for your address, Send for transfers, and Swap to prepare conversion flow.',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 11,
                    weight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WalletAssetDetailScreen extends StatefulWidget {
  const WalletAssetDetailScreen({
    super.key,
    required this.assetCode,
  });

  final String assetCode;

  @override
  State<WalletAssetDetailScreen> createState() =>
      _WalletAssetDetailScreenState();
}

class _WalletAssetDetailScreenState extends State<WalletAssetDetailScreen> {
  late final String _assetCode;

  @override
  void initState() {
    super.initState();
    _assetCode = widget.assetCode.trim().toUpperCase();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final walletStore = context.read<WalletStore>();
      walletStore.loadWalletSummary(force: false);
      walletStore.loadAssetActivity(_assetCode, force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final asset = walletStore.findAsset(_assetCode);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          asset?.name ?? _assetCode,
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
        onRefresh: () async {
          await walletStore.loadWalletSummary(force: true);
          await walletStore.refreshAsset(_assetCode);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _AssetBalanceCard(assetCode: _assetCode),
                const SizedBox(height: 16),
                _ActionRow(assetCode: _assetCode),
                const SizedBox(height: 24),
                _SectionHeader(label: 'Transactions'),
                const SizedBox(height: 8),
                _TransactionsList(assetCode: _assetCode),
                const SizedBox(height: 20),
                if (!walletStore.canTransferAsset(_assetCode) ||
                    !walletStore.canWithdrawAsset(_assetCode))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      'Send and withdrawal are currently disabled for $_assetCode. '
                      'Receive/deposit is available.',
                      style: AppTypography.custom(
                        size: 12,
                        weight: FontWeight.w400,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
