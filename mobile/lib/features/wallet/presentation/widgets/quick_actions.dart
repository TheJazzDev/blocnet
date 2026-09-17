import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/pages/wallet_receive_screen.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_button.dart';
import 'package:flutter/material.dart';

/// The wallet tab's two actions: Receive (outlined) and Send (filled).
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return WalletActionPair(
      onReceive: () => openWalletReceive(context),
      onSend: () => openSendFlow(context),
    );
  }
}

/// Receive and Send side by side, as on the tab and on an asset.
class WalletActionPair extends StatelessWidget {
  const WalletActionPair({
    super.key,
    required this.onReceive,
    required this.onSend,
  });

  final VoidCallback onReceive;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: WalletButton.outlined(
            icon: Icons.arrow_downward_rounded,
            label: 'Receive',
            onPressed: onReceive,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: WalletButton(
            icon: Icons.arrow_upward_rounded,
            label: 'Send',
            onPressed: onSend,
          ),
        ),
      ],
    );
  }
}
