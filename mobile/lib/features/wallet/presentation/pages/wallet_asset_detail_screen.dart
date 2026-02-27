import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/wallet/presentation/widgets/action_row.dart';
import 'package:blocnet/features/wallet/presentation/widgets/asset_balance_card.dart';
import 'package:blocnet/features/wallet/presentation/widgets/section_header.dart';
import 'package:blocnet/features/wallet/presentation/widgets/transactions_list.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                AssetBalanceCard(assetCode: _assetCode),
                const SizedBox(height: 16),
                ActionRow(assetCode: _assetCode),
                const SizedBox(height: 24),
                const SectionHeader(label: 'Transactions'),
                const SizedBox(height: 8),
                TransactionsList(assetCode: _assetCode),
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
