import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final walletStore = context.read<WalletStore>();
      walletStore.loadWalletSummary(force: true);
      walletStore.loadTransactions(force: true);
      walletStore.loadWithdrawals(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final error = walletStore.lastError;

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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                _BalanceCard(),
                SizedBox(height: 20),
                _QuickActions(),
                SizedBox(height: 24),
                _SectionHeader(label: 'Assets'),
                SizedBox(height: 10),
                _AssetsSection(),
                SizedBox(height: 24),
                _SectionHeader(
                  label: 'Recent Activity',
                  actionLabel: 'View all',
                  actionRoute: AppRoutes.walletTransactions,
                ),
                SizedBox(height: 8),
                _TransactionsList(limit: 6),
                SizedBox(height: 16),
                _DisclaimerText(),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: error == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Wallet sync warning: $error',
                  style: AppTypography.custom(
                    size: 11,
                    weight: FontWeight.w400,
                    color: AppColors.textFaint,
                  ),
                ),
              ),
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
    final error = walletStore.lastError;
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
      bottomNavigationBar: error == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Wallet sync warning: $error',
                  style: AppTypography.custom(
                    size: 11,
                    weight: FontWeight.w400,
                    color: AppColors.textFaint,
                  ),
                ),
              ),
            ),
    );
  }
}
