import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_state_views.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_details_sheet.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_row.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_rows.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wallet activity (or one asset's) as rows in one card.
class TransactionsList extends StatelessWidget {
  const TransactionsList({
    super.key,
    this.limit,
    this.assetCode,
  });

  final int? limit;
  final String? assetCode;

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final rows = buildWalletActivityRows(walletStore, assetCode: assetCode);
    final visibleRows = limit == null ? rows : rows.take(limit!).toList();
    final selectedAsset = assetCode?.toUpperCase();
    final isLoading = selectedAsset == null
        ? walletStore.isLoadingTransactions || walletStore.isLoadingWithdrawals
        : walletStore.isLoadingTransactionsForAsset(selectedAsset) ||
            walletStore.isLoadingWithdrawalsForAsset(selectedAsset);

    if (isLoading && rows.isEmpty) return const WalletLoadingCard();

    if (rows.isEmpty) {
      return WalletNoticeCard(
        icon: Icons.receipt_long_outlined,
        message: selectedAsset == null
            ? 'No transactions yet'
            : 'No $selectedAsset transactions yet',
        detail: 'Sends and receipts show up here.',
      );
    }

    return AppRowGroup(
      children: [
        for (final row in visibleRows)
          WalletActivityRow(
            key: ValueKey(row.id),
            item: row,
            onTap: _canOpen(row)
                ? () => showWalletActivityDetails(context, row)
                : null,
          ),
      ],
    );
  }

  static bool _canOpen(WalletActivityItem row) =>
      row.transaction != null || row.withdrawal != null;
}
