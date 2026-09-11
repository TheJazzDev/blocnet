import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/receive_address_card.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
        message: 'Unable to open share options right now.',
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
        title: Text(
          'Receive',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 18,
            weight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
              _WalletNotReadyCard(message: walletNotReadyMessage(walletStore)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only send BNB and BEP-20 tokens on $networkLabel to '
                      'this address. Assets sent on another network cannot '
                      'be recovered.',
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 12,
                        weight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletNotReadyCard extends StatelessWidget {
  const _WalletNotReadyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            size: 32,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Address not ready',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 15,
              weight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 12,
              weight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
