import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/pages/points_receive_screen.dart';
import 'package:blocnet/features/wallet/presentation/pages/wallet_receive_screen.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/quick_actions.dart';
import 'package:flutter/material.dart';

/// Receive / Send for one asset.
class ActionRow extends StatelessWidget {
  const ActionRow({super.key, this.assetCode = 'BNT'});

  final String assetCode;

  bool get _isPoints => assetCode.toUpperCase() == walletPointsAsset;

  @override
  Widget build(BuildContext context) {
    return WalletActionPair(
      // BNP is received by @username; the on-chain address cannot hold it.
      onReceive: () =>
          _isPoints ? openPointsReceive(context) : openWalletReceive(context),
      onSend: () => openSendFlow(context, assetCode: assetCode),
    );
  }
}
