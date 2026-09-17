import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/shared/utils/format_number_utils.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

export 'wallet_error_text.dart';
export 'wallet_send_flow.dart' show openSendFlow;

Color assetAccentColor(String assetCode) {
  switch (assetCode.toUpperCase()) {
    case walletPointsAsset:
      return AppColors.tagPartnership;
    case 'BNB':
      return AppColors.chainBsc;
    case 'USDT':
      return AppColors.successColor;
    case 'BNT':
    default:
      return AppColors.primary400;
  }
}

String formatUsd(String value, {int decimals = 2}) {
  return formatGroupedAmount(
    value,
    maxDecimals: decimals,
    minDecimals: decimals,
  );
}

/// A `priceSource` of `'fallback'` means the backend has no live market
/// price for this asset (either no provider is configured yet, or pricing
/// is deliberately hidden outside mainnet) — showing a dollar figure in
/// that case would be inventing a number, so callers should show honest
/// "no market value yet" copy instead.
bool isUsdPriceLive(String priceSource) => priceSource == 'live';

String formatTokenAmount(
  String value, {
  int maxDecimals = 6,
  int minDecimals = 0,
  bool absolute = false,
}) {
  return formatGroupedAmount(
    value,
    maxDecimals: maxDecimals,
    minDecimals: minDecimals,
    absolute: absolute,
  );
}

String formatCount(num value) {
  return formatGroupedNumber(value, maxDecimals: 0);
}

String assetBadgeText(WalletAssetBalance asset) {
  if (asset.isPoints) return 'In-app';
  return asset.isNative ? 'BSC' : 'BEP-20';
}

/// Balance in the asset's own precision: BNP has 3 decimals, tokens up to 6.
String formatAssetAmount(WalletAssetBalance asset, {String? value}) {
  return formatTokenAmount(
    value ?? asset.available,
    maxDecimals: asset.isPoints ? (asset.decimals ?? 3) : 6,
  );
}

String truncateMiddle(String value, {int head = 8, int tail = 6}) {
  if (value.isEmpty) return value;
  if (value.length <= head + tail + 3) return value;
  final prefix = value.substring(0, head);
  final suffix = value.substring(value.length - tail);
  return '$prefix...$suffix';
}

String formatDate(DateTime? value) {
  if (value == null) return 'just now';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final month = months[local.month - 1];
  return '$month ${local.day}, ${local.year} • $hour:$minute';
}

/// Withdrawal status colour: amber while it waits, accent while it moves,
/// green when done, red when it did not happen.
Color statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return AppColors.successColor;
    case 'rejected':
    case 'reverted':
    case 'failed':
      return AppColors.tagWarning;
    case 'pending_review':
    case 'requested':
      return AppColors.warning500;
    case 'broadcasting':
    case 'approved':
      return AppColors.primary500;
    default:
      return AppColors.textMuted;
  }
}

/// Withdrawal status in a member's words.
String withdrawalStatusLabel(String status) {
  switch (status) {
    case 'requested':
    case 'pending_review':
      return 'In review';
    case 'approved':
      return 'Approved';
    case 'broadcasting':
      return 'Sending';
    case 'confirmed':
      return 'Sent';
    case 'rejected':
      return 'Rejected';
    case 'reverted':
    case 'failed':
      return 'Failed';
    default:
      return toTitleCase(status);
  }
}

/// Shown for a failed withdrawal when the server gives no reason.
const String withdrawalFailedFallback =
    'Withdrawal failed. The amount is back in your wallet.';

/// What to tell the member about a failed withdrawal: the server's text
/// (already written for members) or [withdrawalFailedFallback].
String withdrawalFailureText(String? failureReason) {
  final text = failureReason?.trim() ?? '';
  return text.isEmpty ? withdrawalFailedFallback : text;
}

String toTitleCase(String value) {
  final words =
      value.split(RegExp(r'[_\s]+')).where((part) => part.isNotEmpty).toList();
  if (words.isEmpty) return value;
  return words
      .map(
        (word) =>
            '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String directionLabel(String direction) {
  switch (direction) {
    case 'incoming':
      return 'Received';
    case 'outgoing':
      return 'Sent';
    default:
      return 'Internal';
  }
}

String trimValue(String? value) {
  return value?.trim() ?? '';
}

String explorerBaseUrlForSnapshot(WalletSnapshot? snapshot) {
  final chainEnvironment =
      snapshot?.walletChainEnvironment.toLowerCase().trim() ?? 'testnet';
  if (chainEnvironment == 'mainnet' || snapshot?.walletChainId == 56) {
    return 'https://bscscan.com';
  }
  return 'https://testnet.bscscan.com';
}

String? buildExplorerTxUrl(WalletSnapshot? snapshot, String txHash) {
  final normalized = trimValue(txHash);
  if (normalized.isEmpty) return null;
  if (!RegExp(r'^0x[a-fA-F0-9]{64}$').hasMatch(normalized)) {
    return null;
  }

  final baseUrl = explorerBaseUrlForSnapshot(snapshot);
  return '$baseUrl/tx/$normalized';
}

Future<void> openExplorerTx(
  BuildContext context,
  String explorerTxUrl,
) async {
  final uri = Uri.tryParse(explorerTxUrl);
  if (uri == null) {
    AppSnackbar.showError(
      context,
      'Invalid explorer URL.',
      duration: AppSnackbar.longDuration,
    );
    return;
  }

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    AppSnackbar.showError(
      context,
      'Could not open block explorer.',
      duration: AppSnackbar.longDuration,
    );
  }
}

bool isWalletReadyForAction(WalletStore store) {
  final status = store.snapshot?.walletStatus ?? 'provisioning';
  return status == 'ready';
}

String walletNotReadyMessage(WalletStore store) {
  final status = store.snapshot?.walletStatus ?? 'provisioning';
  if (store.isLoadingSummary && store.snapshot == null) {
    return 'Wallet is syncing. Try again in a moment.';
  }

  if (status == 'disabled') {
    return 'Wallet is currently disabled.';
  }

  if (status == 'error') {
    return 'Wallet setup has an issue. Pull to refresh and try again.';
  }

  return 'Wallet is not ready yet.';
}
