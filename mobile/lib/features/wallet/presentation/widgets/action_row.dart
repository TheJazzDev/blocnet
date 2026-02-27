import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/action_button.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ActionRow extends StatelessWidget {
  const ActionRow({super.key, this.assetCode = 'BNT'});

  final String assetCode;

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final address = walletStore.snapshot?.walletAddress;
    final hasAddress = address != null && address.isNotEmpty;

    return Row(
      children: [
        ActionButton(
          icon: Icons.arrow_upward_rounded,
          label: 'Send',
          onTap: () => openSendFlow(context, assetCode: assetCode),
        ),
        const SizedBox(width: 10),
        ActionButton(
          icon: Icons.arrow_downward_rounded,
          label: 'Receive',
          onTap: () {
            if (!hasAddress) {
              showWalletToast(
                context,
                message: walletNotReadyMessage(walletStore),
                type: WalletToastType.error,
              );
              return;
            }
            Clipboard.setData(ClipboardData(text: address));
            showWalletToast(
              context,
              message: 'Wallet address copied successfully.',
              type: WalletToastType.success,
            );
          },
        ),
      ],
    );
  }
}
