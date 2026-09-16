import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/pages/wallet_receive_screen.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/action_button.dart';
import 'package:flutter/material.dart';

class ActionRow extends StatelessWidget {
  const ActionRow({super.key, this.assetCode = 'BNT'});

  final String assetCode;

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
          onTap: () => openWalletReceive(context),
        ),
      ],
    );
  }
}
