import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/pages/send_points_page.dart';
import 'package:blocnet/features/wallet/presentation/pages/send_token_page.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/send_asset_picker_sheet.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Send entry point for every asset. BNP goes to [SendPointsPage] (member to
/// member by @username, independent of the on-chain wallet); tokens go to
/// [SendTokenPage] and need a ready on-chain wallet.
Future<void> openSendFlow(
  BuildContext context, {
  String? assetCode,
}) async {
  final walletStore = context.read<WalletStore>();
  String? selectedAsset = assetCode?.trim().toUpperCase();
  if (selectedAsset == null || selectedAsset.isEmpty) {
    selectedAsset = await _pickAsset(context, walletStore);
    if (selectedAsset == null || selectedAsset.isEmpty) {
      return;
    }
  }
  if (!context.mounted) return;
  final resolvedAsset = selectedAsset;

  final String? resultMessage;
  if (resolvedAsset == walletPointsAsset) {
    resultMessage = await _openPointsSend(context, walletStore);
  } else {
    resultMessage = await _openTokenSend(context, walletStore, resolvedAsset);
  }

  if (!context.mounted || resultMessage == null || resultMessage.isEmpty) {
    return;
  }

  showWalletToast(
    context,
    message: resultMessage,
    type: WalletToastType.success,
  );
}

Future<String?> _openPointsSend(
  BuildContext context,
  WalletStore walletStore,
) async {
  final asset = walletStore.findAsset(walletPointsAsset);
  if (asset == null || !asset.canSend) {
    showWalletToast(
      context,
      message: 'Sending BNP is unavailable right now.',
      type: WalletToastType.info,
    );
    return null;
  }

  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => SendPointsPage(asset: asset)),
  );
}

Future<String?> _openTokenSend(
  BuildContext context,
  WalletStore walletStore,
  String assetCode,
) async {
  final canTransfer = walletStore.canTransferAsset(assetCode);
  final canWithdraw = walletStore.canWithdrawAsset(assetCode);

  if (!isWalletReadyForAction(walletStore)) {
    showWalletToast(
      context,
      message: walletNotReadyMessage(walletStore),
      type: WalletToastType.error,
    );
    return null;
  }

  if (!canTransfer && !canWithdraw) {
    showWalletToast(
      context,
      message: '$assetCode send and withdrawal are currently disabled.',
      type: WalletToastType.info,
    );
    return null;
  }

  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => SendTokenPage(
        assetCode: assetCode,
        canTransfer: canTransfer,
        canWithdraw: canWithdraw,
      ),
    ),
  );
}

Future<String?> _pickAsset(
  BuildContext context,
  WalletStore walletStore,
) async {
  final assets = walletStore.snapshot?.assets ?? const <WalletAssetBalance>[];
  if (assets.isEmpty) {
    showWalletToast(
      context,
      message: 'No wallet assets available to send right now.',
      type: WalletToastType.info,
    );
    return null;
  }

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => SendAssetPickerSheet(assets: assets),
  );
}
