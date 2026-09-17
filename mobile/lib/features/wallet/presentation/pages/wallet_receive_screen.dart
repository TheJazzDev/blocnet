import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/receive_address_card.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_state_views.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Opens [WalletReceiveScreen]; every Receive entry point uses this.
Future<void> openWalletReceive(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const WalletReceiveScreen()),
  );
}

/// Receive view: the wallet's BSC address as a QR code plus copy/share.
///
/// Reads the address straight from the wallet snapshot; when the wallet is
/// still provisioning (or disabled) it shows the same status copy the
/// balance card uses instead of an empty QR.
class WalletReceiveScreen extends StatelessWidget {
  const WalletReceiveScreen({super.key});

  Future<void> _share(BuildContext context, String address) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: address, subject: 'My Blocnet wallet address'),
      );
    } catch (_) {
      if (!context.mounted) return;
      showWalletToast(
        context,
        message: "Couldn't open sharing.",
        type: WalletToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final snapshot = walletStore.snapshot;
    final address = snapshot?.walletAddress?.trim() ?? '';
    final hasAddress = address.isNotEmpty;
    final networkLabel =
        snapshot?.walletChainEnvironment.toLowerCase() == 'mainnet'
            ? 'BNB Smart Chain (BSC)'
            : 'BNB Smart Chain (BSC testnet)';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text('Receive', style: AppText.title(AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          AppSpace.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasAddress)
              ReceiveAddressCard(
                address: address,
                networkLabel: networkLabel,
                onShare: () => _share(context, address),
              )
            else
              WalletNoticeCard(
                icon: Icons.hourglass_top_rounded,
                message: 'Address not ready',
                detail: walletNotReadyMessage(walletStore),
              ),
            const SizedBox(height: AppSpace.md),
            WalletNoticeCard(
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.warning500,
              message: 'Only BNB and BEP-20 tokens',
              detail: 'Send them on $networkLabel. Tokens sent on another '
                  'network are lost.',
            ),
          ],
        ),
      ),
    );
  }
}
