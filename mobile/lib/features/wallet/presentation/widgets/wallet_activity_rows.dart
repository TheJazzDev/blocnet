import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';

/// One row of wallet activity: a ledger transaction or a withdrawal request.
class WalletActivityItem {
  const WalletActivityItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.amountColor,
    required this.occurredAt,
    required this.isOutgoing,
    required this.isIncoming,
    this.transaction,
    this.withdrawal,
    this.badgeLabel,
    this.badgeColor,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String amountLabel;
  final Color amountColor;
  final DateTime? occurredAt;
  final bool isOutgoing;
  final bool isIncoming;
  final WalletTransaction? transaction;
  final WalletWithdrawalRequest? withdrawal;
  final String? badgeLabel;
  final Color? badgeColor;
}

/// Transactions and withdrawals for the wallet (or one asset), newest first.
List<WalletActivityItem> buildWalletActivityRows(
  WalletStore walletStore, {
  String? assetCode,
}) {
  final rows = <WalletActivityItem>[];
  final transactionIds = <String>{};
  final selectedAsset = assetCode?.toUpperCase();

  final transactions = selectedAsset == null
      ? walletStore.transactions
      : walletStore.transactionsForAsset(selectedAsset);
  final withdrawals = selectedAsset == null
      ? walletStore.withdrawals
      : walletStore.withdrawalsForAsset(selectedAsset);

  for (final tx in transactions) {
    if (tx.id.isNotEmpty) {
      transactionIds.add(tx.id);
    }

    final isOutgoing = tx.direction == 'outgoing';
    final isIncoming = tx.direction == 'incoming';
    final sign = isOutgoing
        ? '-'
        : isIncoming
            ? '+'
            : '';
    final icon = isOutgoing
        ? Icons.arrow_upward_rounded
        : isIncoming
            ? Icons.arrow_downward_rounded
            : Icons.swap_horiz_rounded;

    rows.add(
      WalletActivityItem(
        id: tx.id.isNotEmpty ? 'tx_${tx.id}' : 'tx_${rows.length}',
        icon: icon,
        // BNP labels arrive readable ("BNP transfer"); ledger reasons
        // arrive in caps and read better in title case.
        title: tx.isPoints ? tx.label : toTitleCase(tx.label),
        subtitle: _transactionSubtitle(tx),
        amountLabel:
            '$sign${formatTokenAmount(tx.amount, absolute: true, maxDecimals: tx.isPoints ? 3 : 6)} ${tx.asset}',
        amountColor: isOutgoing
            ? AppColors.textPrimary
            : isIncoming
                ? AppColors.successColor
                : AppColors.textMuted,
        occurredAt: tx.createdAt,
        isOutgoing: isOutgoing,
        isIncoming: isIncoming,
        transaction: tx,
      ),
    );
  }

  for (final withdrawal in withdrawals) {
    if (withdrawal.id.isNotEmpty && transactionIds.contains(withdrawal.id)) {
      continue;
    }

    final statusLabel = withdrawalStatusLabel(withdrawal.status);
    final addressLabel = withdrawal.toAddress.isEmpty
        ? 'outside wallet'
        : truncateMiddle(withdrawal.toAddress);

    rows.add(
      WalletActivityItem(
        id: withdrawal.id.isNotEmpty
            ? 'withdrawal_${withdrawal.id}'
            : 'withdrawal_${rows.length}',
        icon: Icons.call_made_rounded,
        title: 'Withdrawal',
        subtitle: 'To $addressLabel • ${formatDate(withdrawal.requestedAt)}',
        amountLabel:
            '-${formatTokenAmount(withdrawal.amount, absolute: true)} ${withdrawal.asset}',
        amountColor: AppColors.textPrimary,
        occurredAt: withdrawal.requestedAt,
        isOutgoing: true,
        isIncoming: false,
        withdrawal: withdrawal,
        badgeLabel: statusLabel,
        badgeColor: statusColor(withdrawal.status),
      ),
    );
  }

  rows.sort((a, b) {
    final aDate = a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });

  return rows;
}

/// BNP rows name the other member (`@bob • date`); on-chain rows show the date.
String _transactionSubtitle(WalletTransaction tx) {
  final date = formatDate(tx.createdAt);
  if (!tx.isPoints) return date;
  final handle = tx.counterparty?.username?.trim() ?? '';
  if (handle.isEmpty) return date;
  final prefix = tx.isOutgoing ? 'To' : 'From';
  return '$prefix @$handle • $date';
}
