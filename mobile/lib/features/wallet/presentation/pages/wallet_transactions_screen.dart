import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/widgets/transactions_list.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Every wallet transaction and withdrawal, newest first.
class WalletTransactionsScreen extends StatelessWidget {
  const WalletTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text('Transactions', style: AppText.title(AppColors.textPrimary)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary500,
        backgroundColor: AppColors.bgSurface,
        onRefresh: walletStore.refreshAll,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
            AppSpace.xl,
          ),
          child: TransactionsList(),
        ),
      ),
    );
  }
}
