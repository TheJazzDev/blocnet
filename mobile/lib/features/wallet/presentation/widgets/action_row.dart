import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/pages/points_receive_screen.dart';
import 'package:blocnet/features/wallet/presentation/pages/wallet_receive_screen.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/action_button.dart';
import 'package:flutter/material.dart';

class ActionRow extends StatelessWidget {
  const ActionRow({super.key, this.assetCode = 'BNT'});

  final String assetCode;

  bool get _isPoints => assetCode.toUpperCase() == walletPointsAsset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ActionButton(
          icon: Icons.arrow_upward_rounded,
          label: 'Send',
          onTap: () => openSendFlow(context, assetCode: assetCode),
        ),
        const SizedBox(width: AppSpace.md),
        ActionButton(
          icon: Icons.arrow_downward_rounded,
          label: 'Receive',
          // BNP is received by @username; the on-chain address cannot hold it.
          onTap: () => _isPoints
              ? openPointsReceive(context)
              : openWalletReceive(context),
        ),
      ],
    );
  }
}
