import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/widgets/action_row.dart';
import 'package:blocnet/features/wallet/presentation/widgets/asset_balance_card.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_state_views.dart';
import 'package:blocnet/features/wallet/presentation/widgets/section_header.dart';
import 'package:blocnet/features/wallet/presentation/widgets/transactions_list.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One asset: balance, Receive / Send, and its transactions.
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
    final notice = _availabilityNotice(walletStore, asset);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          asset?.name ?? _assetCode,
          style: AppText.title(AppColors.textPrimary),
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
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
            AppSpace.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AssetBalanceCard(assetCode: _assetCode),
              const SizedBox(height: AppSpace.md),
              ActionRow(assetCode: _assetCode),
              if (notice != null) ...[
                const SizedBox(height: AppSpace.md),
                WalletNoticeCard(
                  icon: Icons.info_outline_rounded,
                  message: notice,
                ),
              ],
              const SizedBox(height: AppSpace.xl),
              const SectionHeader(
                icon: Icons.receipt_long_outlined,
                label: 'Transactions',
              ),
              const SizedBox(height: AppSpace.sm),
              TransactionsList(assetCode: _assetCode),
            ],
          ),
        ),
      ),
    );
  }

  /// Why some actions are off for this asset, or null when all are on.
  /// BNP has no withdrawals; only its own send switch matters.
  String? _availabilityNotice(
    WalletStore walletStore,
    WalletAssetBalance? asset,
  ) {
    if (_assetCode == walletPointsAsset) {
      if (asset == null || asset.canSend) return null;
      return 'Sending BNP is off right now.';
    }
    final canSend = walletStore.canTransferAsset(_assetCode);
    final canWithdraw = walletStore.canWithdrawAsset(_assetCode);
    if (canSend && canWithdraw) return null;
    if (!canSend && !canWithdraw) {
      return 'Sending $_assetCode is off right now. You can still receive it.';
    }
    return canSend
        ? 'Withdrawals of $_assetCode are off. Sends inside Blocnet work.'
        : 'Sends inside Blocnet are off for $_assetCode. Withdrawals work.';
  }
}
