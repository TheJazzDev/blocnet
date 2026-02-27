import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class _WalletActivityItem {
  const _WalletActivityItem({
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

class _WalletDetailField {
  const _WalletDetailField({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final String label;
  final String value;
  final bool copyable;
}

class TransactionsList extends StatelessWidget {
  const TransactionsList({
    super.key,
    this.limit,
    this.assetCode,
  });

  final int? limit;
  final String? assetCode;

  void _showCopiedToast(BuildContext context, String message) {
    showWalletToast(
      context,
      message: message,
      type: WalletToastType.success,
    );
  }

  void _showTransactionDetails(BuildContext context, _WalletActivityItem row) {
    final tx = row.transaction;
    final withdrawal = row.withdrawal;
    if (tx == null && withdrawal == null) {
      return;
    }

    final fields = <_WalletDetailField>[];
    String? explorerTxUrl;
    if (tx != null) {
      final metadata = tx.metadata;
      final counterparty = tx.counterparty;
      final counterpartyLabel = counterparty?.preferredLabel ?? '';
      final counterpartyAddress = trimValue(
        counterparty?.walletAddress ??
            (tx.isOutgoing
                ? tx.metadataString('recipientAddress')
                : tx.metadataString('senderAddress')),
      );
      final fromAddress = trimValue(tx.metadataString('fromAddress'));
      final toAddress = trimValue(tx.metadataString('toAddress'));
      final txHash = trimValue(tx.metadataString('txHash'));
      final note = trimValue(tx.metadataString('note'));
      explorerTxUrl = buildExplorerTxUrl(context.read<WalletStore>().snapshot, txHash);

      fields.addAll([
        _WalletDetailField(label: 'Type', value: toTitleCase(tx.reason)),
        _WalletDetailField(
            label: 'Direction', value: directionLabel(tx.direction)),
        _WalletDetailField(label: 'Amount', value: '${tx.amount} ${tx.asset}'),
        _WalletDetailField(label: 'Date', value: formatDate(tx.createdAt)),
      ]);

      if (counterpartyLabel.isNotEmpty) {
        fields.add(_WalletDetailField(
            label: 'Counterparty', value: counterpartyLabel));
      }
      if (counterpartyAddress.isNotEmpty) {
        fields.add(
          _WalletDetailField(
            label: 'Counterparty Wallet',
            value: counterpartyAddress,
            copyable: true,
          ),
        );
      }
      if (fromAddress.isNotEmpty) {
        fields.add(
          _WalletDetailField(
              label: 'From Wallet', value: fromAddress, copyable: true),
        );
      }
      if (toAddress.isNotEmpty) {
        fields.add(
          _WalletDetailField(
              label: 'To Wallet', value: toAddress, copyable: true),
        );
      }
      if (txHash.isNotEmpty) {
        fields.add(
          _WalletDetailField(
              label: 'Transaction Hash', value: txHash, copyable: true),
        );
      }
      final logIndex = tx.metadataInt('logIndex');
      if (logIndex != null) {
        fields.add(
            _WalletDetailField(label: 'Log Index', value: logIndex.toString()));
      }
      final depositId = trimValue(metadata?['depositId']?.toString());
      if (depositId.isNotEmpty) {
        fields.add(_WalletDetailField(
            label: 'Deposit ID', value: depositId, copyable: true));
      }
      if (note.isNotEmpty) {
        fields.add(_WalletDetailField(label: 'Note', value: note));
      }
      if (tx.referenceId != null && tx.referenceId!.trim().isNotEmpty) {
        fields.add(
          _WalletDetailField(
            label: 'Reference ID',
            value: tx.referenceId!,
            copyable: true,
          ),
        );
      }
      fields.add(_WalletDetailField(
          label: 'Ledger Entry ID', value: tx.id, copyable: true));
    }

    if (withdrawal != null) {
      fields.addAll([
        _WalletDetailField(label: 'Type', value: 'Withdrawal'),
        _WalletDetailField(
            label: 'Status', value: toTitleCase(withdrawal.status)),
        _WalletDetailField(
          label: 'Amount',
          value: '-${withdrawal.amount} ${withdrawal.asset}',
        ),
        _WalletDetailField(
          label: 'Destination Wallet',
          value: withdrawal.toAddress,
          copyable: true,
        ),
        _WalletDetailField(label: 'Reason', value: withdrawal.reason),
        _WalletDetailField(
          label: 'Requested At',
          value: formatDate(withdrawal.requestedAt),
        ),
      ]);
      if (withdrawal.broadcastTxHash != null &&
          withdrawal.broadcastTxHash!.trim().isNotEmpty) {
        explorerTxUrl ??=
            buildExplorerTxUrl(context.read<WalletStore>().snapshot, withdrawal.broadcastTxHash!);
        fields.add(
          _WalletDetailField(
            label: 'Broadcast Tx Hash',
            value: withdrawal.broadcastTxHash!,
            copyable: true,
          ),
        );
      }
      if (withdrawal.rejectReason != null &&
          withdrawal.rejectReason!.trim().isNotEmpty) {
        fields.add(
          _WalletDetailField(
              label: 'Reject Reason', value: withdrawal.rejectReason!),
        );
      }
      if (withdrawal.failureReason != null &&
          withdrawal.failureReason!.trim().isNotEmpty) {
        fields.add(
          _WalletDetailField(
              label: 'Failure Reason', value: withdrawal.failureReason!),
        );
      }
      fields.add(
        _WalletDetailField(
          label: 'Withdrawal ID',
          value: withdrawal.id,
          copyable: true,
        ),
      );
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final title =
            tx != null ? toTitleCase(tx.reason) : 'Withdrawal Details';
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              18 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderMuted,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 18,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...fields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field.label,
                                    style: AppTypography.custom(
                                      color: AppColors.textFaint,
                                      size: 11,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    field.value,
                                    style: AppTypography.custom(
                                      color: AppColors.textSecondary,
                                      size: 12,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (field.copyable) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: field.value),
                                  );
                                  _showCopiedToast(
                                    sheetContext,
                                    '${field.label} copied.',
                                  );
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.bgSurface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.borderSubtle),
                                  ),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 15,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  if (explorerTxUrl != null) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => openExplorerTx(
                          sheetContext,
                          explorerTxUrl!,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Verify on block explorer'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<_WalletActivityItem> _buildRows(WalletStore walletStore) {
    final rows = <_WalletActivityItem>[];
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
        _WalletActivityItem(
          id: tx.id.isNotEmpty ? 'tx_${tx.id}' : 'tx_${rows.length}',
          icon: icon,
          title: tx.reason.replaceAll('_', ' ').toUpperCase(),
          subtitle: formatDate(tx.createdAt),
          amountLabel: '$sign${tx.amount} ${tx.asset}',
          amountColor: isOutgoing
              ? AppColors.error500
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

      final statusLabel = withdrawal.status.replaceAll('_', ' ').toUpperCase();
      final addressLabel = withdrawal.toAddress.isEmpty
          ? 'External wallet'
          : truncateMiddle(withdrawal.toAddress);

      rows.add(
        _WalletActivityItem(
          id: withdrawal.id.isNotEmpty
              ? 'withdrawal_${withdrawal.id}'
              : 'withdrawal_${rows.length}',
          icon: Icons.call_made_rounded,
          title: 'WITHDRAWAL',
          subtitle: '$addressLabel • ${formatDate(withdrawal.requestedAt)}',
          amountLabel: '-${withdrawal.amount} ${withdrawal.asset}',
          amountColor: AppColors.error500,
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

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final rows = _buildRows(walletStore);
    final visibleRows = limit == null ? rows : rows.take(limit!).toList();
    final selectedAsset = assetCode?.toUpperCase();
    final isLoading = selectedAsset == null
        ? walletStore.isLoadingTransactions || walletStore.isLoadingWithdrawals
        : walletStore.isLoadingTransactionsForAsset(selectedAsset) ||
            walletStore.isLoadingWithdrawalsForAsset(selectedAsset);

    if (isLoading && rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.teal400,
            strokeWidth: 2.2,
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      final title = selectedAsset == null
          ? 'No transactions yet'
          : 'No $selectedAsset transactions yet';
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.textFaint,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.custom(
                color: AppColors.textSecondary,
                size: 14,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your wallet activity will appear here after your first transaction.',
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: 12,
                weight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: visibleRows.map((row) {
        final badgeColor = row.badgeColor;
        final canOpenDetails =
            row.transaction != null || row.withdrawal != null;

        return Padding(
          key: ValueKey(row.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: canOpenDetails
                ? () => _showTransactionDetails(context, row)
                : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.borderSubtle.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: row.isIncoming
                          ? AppColors.successColor.withValues(alpha: 0.12)
                          : row.isOutgoing
                              ? AppColors.primary500.withValues(alpha: 0.12)
                              : AppColors.bgElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      row.icon,
                      size: 18,
                      color: row.isIncoming
                          ? AppColors.successColor
                          : row.isOutgoing
                              ? AppColors.primary500
                              : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                row.title,
                                style: AppTypography.custom(
                                  color: AppColors.textPrimary,
                                  size: 13,
                                  weight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (row.badgeLabel != null &&
                                badgeColor != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  row.badgeLabel!,
                                  style: AppTypography.custom(
                                    color: badgeColor,
                                    size: 8,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          row.subtitle,
                          style: AppTypography.custom(
                            color: AppColors.textFaint,
                            size: 11,
                            weight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        row.amountLabel,
                        style: AppTypography.custom(
                          color: row.amountColor,
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
                      if (canOpenDetails) ...[
                        const SizedBox(height: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.textFaint,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
