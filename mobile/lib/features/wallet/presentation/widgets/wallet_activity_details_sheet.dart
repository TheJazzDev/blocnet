import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_rows.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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

void _showCopiedToast(BuildContext context, String message) {
  showWalletToast(
    context,
    message: message,
    type: WalletToastType.success,
  );
}

/// Bottom sheet with every detail of one activity row.
void showWalletActivityDetails(BuildContext context, WalletActivityItem row) {
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
    explorerTxUrl =
        buildExplorerTxUrl(context.read<WalletStore>().snapshot, txHash);

    fields.addAll([
      _WalletDetailField(label: 'Type', value: toTitleCase(tx.reason)),
      _WalletDetailField(
          label: 'Direction', value: directionLabel(tx.direction)),
      _WalletDetailField(
        label: 'Amount',
        value: '${formatTokenAmount(tx.amount)} ${tx.asset}',
      ),
      _WalletDetailField(label: 'Date', value: formatDate(tx.createdAt)),
    ]);

    if (counterpartyLabel.isNotEmpty) {
      fields.add(
          _WalletDetailField(label: 'Counterparty', value: counterpartyLabel));
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
        value:
            '-${formatTokenAmount(withdrawal.amount, absolute: true)} ${withdrawal.asset}',
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
      explorerTxUrl ??= buildExplorerTxUrl(
          context.read<WalletStore>().snapshot, withdrawal.broadcastTxHash!);
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
      final title = tx != null ? toTitleCase(tx.reason) : 'Withdrawal Details';
      return SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
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
                      borderRadius: BorderRadius.circular(AppRadius.fullValue),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  title,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: AppText.titleSize,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                ...fields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.md,
                        vertical: AppSpace.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(AppRadius.mdValue),
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
                                    size: AppText.captionSize,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpace.hair),
                                Text(
                                  field.value,
                                  style: AppTypography.custom(
                                    color: AppColors.textSecondary,
                                    size: AppText.labelSize,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (field.copyable) ...[
                            const SizedBox(width: AppSpace.sm),
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
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.smValue),
                                  border:
                                      Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: AppIcon.sm,
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
                  const SizedBox(height: AppSpace.xs),
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
                          borderRadius:
                              BorderRadius.circular(AppRadius.mdValue),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded,
                          size: AppIcon.md),
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
