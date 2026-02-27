import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/pages/send_token_page.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum WalletToastType { info, success, error }

Color assetAccentColor(String assetCode) {
  switch (assetCode.toUpperCase()) {
    case 'BNB':
      return const Color(0xFFF3BA2F);
    case 'USDT':
      return const Color(0xFF26A17B);
    case 'BNT':
    default:
      return AppColors.teal400;
  }
}

String formatUsd(String value, {int decimals = 2}) {
  final parsed = num.tryParse(value);
  if (parsed == null) return value;
  return parsed.toStringAsFixed(decimals);
}

String assetBadgeText(WalletAssetBalance asset) {
  return asset.isNative ? 'BSC' : 'BEP-20';
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

Color statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return AppColors.successColor;
    case 'rejected':
    case 'reverted':
    case 'failed':
      return AppColors.error500;
    case 'broadcasting':
    case 'approved':
    case 'pending_review':
    case 'requested':
      return AppColors.primary500;
    default:
      return AppColors.textMuted;
  }
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
    showWalletToast(
      context,
      message: 'Invalid explorer URL.',
      type: WalletToastType.error,
    );
    return;
  }

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    showWalletToast(
      context,
      message: 'Could not open block explorer.',
      type: WalletToastType.error,
    );
  }
}

void showWalletToast(
  BuildContext context, {
  required String message,
  WalletToastType type = WalletToastType.info,
}) {
  final messenger = ScaffoldMessenger.of(context);

  Color backgroundColor;
  Color borderColor;
  IconData icon;

  switch (type) {
    case WalletToastType.success:
      backgroundColor = const Color(0xFF0D2A22);
      borderColor = AppColors.successColor.withValues(alpha: 0.65);
      icon = Icons.check_circle_rounded;
      break;
    case WalletToastType.error:
      backgroundColor = AppColors.error900.withValues(alpha: 0.95);
      borderColor = AppColors.error500.withValues(alpha: 0.75);
      icon = Icons.error_rounded;
      break;
    case WalletToastType.info:
      backgroundColor = const Color(0xFF0B2A30);
      borderColor = AppColors.primary500.withValues(alpha: 0.55);
      icon = Icons.info_rounded;
      break;
  }

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 6),
      showCloseIcon: true,
      closeIconColor: AppColors.textMuted,
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

Future<void> openSendFlow(
  BuildContext context, {
  required String assetCode,
}) async {
  final walletStore = context.read<WalletStore>();
  final selectedAsset = assetCode.trim().toUpperCase();
  final canTransfer = walletStore.canTransferAsset(selectedAsset);
  final canWithdraw = walletStore.canWithdrawAsset(selectedAsset);

  if (!isWalletReadyForAction(walletStore)) {
    showWalletToast(
      context,
      message: walletNotReadyMessage(walletStore),
      type: WalletToastType.error,
    );
    return;
  }

  if (!canTransfer && !canWithdraw) {
    showWalletToast(
      context,
      message: '$selectedAsset send and withdrawal are currently disabled.',
      type: WalletToastType.info,
    );
    return;
  }

  final resultMessage = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => SendTokenPage(
        assetCode: selectedAsset,
        canTransfer: canTransfer,
        canWithdraw: canWithdraw,
      ),
    ),
  );

  if (!context.mounted || resultMessage == null || resultMessage.isEmpty) {
    return;
  }

  showWalletToast(
    context,
    message: resultMessage,
    type: WalletToastType.success,
  );
}
