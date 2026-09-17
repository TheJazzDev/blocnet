import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_rows.dart';

/// One labelled line in the activity detail sheet.
class WalletDetailField {
  const WalletDetailField(this.label, this.value, {this.copyable = false});

  final String label;
  final String value;
  final bool copyable;
}

/// Everything the detail sheet shows for [row], plus the explorer link.
class WalletActivityDetails {
  const WalletActivityDetails({
    required this.title,
    required this.fields,
    this.explorerUrl,
  });

  final String title;
  final List<WalletDetailField> fields;
  final String? explorerUrl;

  factory WalletActivityDetails.from(
    WalletActivityItem row,
    WalletSnapshot? snapshot,
  ) {
    final tx = row.transaction;
    if (tx != null) return _forTransaction(tx, snapshot);
    return _forWithdrawal(row.withdrawal!, snapshot);
  }

  static WalletActivityDetails _forTransaction(
    WalletTransaction tx,
    WalletSnapshot? snapshot,
  ) {
    final decimals = tx.isPoints ? 3 : 6;
    final counterparty = tx.counterparty;
    final counterpartyAddress = trimValue(
      counterparty?.walletAddress ??
          (tx.isOutgoing
              ? tx.metadataString('recipientAddress')
              : tx.metadataString('senderAddress')),
    );
    final txHash = trimValue(tx.metadataString('txHash'));
    final fee = double.tryParse(tx.feeAmount) ?? 0;
    final logIndex = tx.metadataInt('logIndex');
    final depositId = trimValue(tx.metadata?['depositId']?.toString());
    final reference = tx.referenceId?.trim() ?? '';

    final fields = <WalletDetailField>[
      WalletDetailField('Type', _typeLabel(tx)),
      WalletDetailField('Direction', directionLabel(tx.direction)),
      WalletDetailField(
        'Amount',
        '${formatTokenAmount(tx.amount, maxDecimals: decimals)} ${tx.asset}',
      ),
      if (fee > 0)
        WalletDetailField(
          'Fee',
          '${formatTokenAmount(tx.feeAmount, maxDecimals: decimals)} ${tx.asset}',
        ),
      WalletDetailField('Date', formatDate(tx.createdAt)),
      ..._optional('Member', counterparty?.preferredLabel ?? ''),
      ..._optional('Their wallet', counterpartyAddress, copyable: true),
      ..._optional('From', trimValue(tx.metadataString('fromAddress')),
          copyable: true),
      ..._optional('To', trimValue(tx.metadataString('toAddress')),
          copyable: true),
      ..._optional('Transaction hash', txHash, copyable: true),
      if (logIndex != null) WalletDetailField('Log index', '$logIndex'),
      ..._optional('Deposit ID', depositId, copyable: true),
      ..._optional('Note', trimValue(tx.metadataString('note'))),
      if (reference.isNotEmpty && reference != tx.id)
        WalletDetailField('Reference', reference, copyable: true),
      WalletDetailField(
        tx.isPoints ? 'Transaction ID' : 'Ledger entry ID',
        tx.id,
        copyable: true,
      ),
    ];
    return WalletActivityDetails(
      title: _typeLabel(tx),
      fields: fields,
      explorerUrl: buildExplorerTxUrl(snapshot, txHash),
    );
  }

  static WalletActivityDetails _forWithdrawal(
    WalletWithdrawalRequest w,
    WalletSnapshot? snapshot,
  ) {
    final hash = w.broadcastTxHash?.trim() ?? '';
    final failure = w.status == 'failed'
        ? withdrawalFailureText(w.failureReason)
        : (w.failureReason?.trim() ?? '');
    final fields = <WalletDetailField>[
      WalletDetailField('Status', withdrawalStatusLabel(w.status)),
      WalletDetailField(
        'Amount',
        '-${formatTokenAmount(w.amount, absolute: true)} ${w.asset}',
      ),
      WalletDetailField('To', w.toAddress, copyable: true),
      ..._optional('Reason', w.reason.trim()),
      WalletDetailField('Requested', formatDate(w.requestedAt)),
      ..._optional('Transaction hash', hash, copyable: true),
      ..._optional('Why it was rejected', w.rejectReason?.trim() ?? ''),
      ..._optional('What happened', failure),
      WalletDetailField('Withdrawal ID', w.id, copyable: true),
    ];
    return WalletActivityDetails(
      title: 'Withdrawal',
      fields: fields,
      explorerUrl: hash.isEmpty ? null : buildExplorerTxUrl(snapshot, hash),
    );
  }

  static List<WalletDetailField> _optional(
    String label,
    String value, {
    bool copyable = false,
  }) =>
      value.isEmpty
          ? const []
          : [WalletDetailField(label, value, copyable: copyable)];
}

/// BNP rows carry a readable label from the backend ("BNP transfer", "Tip").
String _typeLabel(WalletTransaction tx) =>
    tx.isPoints ? tx.label : toTitleCase(tx.reason);
