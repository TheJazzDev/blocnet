import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// The on-chain address (shortened) with a copy action, or the wallet's
/// setup state while there is no address.
class WalletAddressRow extends StatelessWidget {
  const WalletAddressRow({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshot = context.watch<WalletStore>().snapshot;
    final address = snapshot?.walletAddress?.trim() ?? '';
    final hasAddress = address.isNotEmpty;
    final network = snapshot?.walletChainEnvironment.toLowerCase() == 'mainnet'
        ? 'BSC'
        : 'BSC testnet';

    return InkWell(
      onTap: hasAddress ? () => _copy(context, address) : null,
      borderRadius: AppRadius.sm,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, AppSpace.md, AppSpace.md, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAddress
                        ? truncateMiddle(address)
                        : _statusText(snapshot?.walletStatus),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                      AppColors.textSecondary,
                      weight: AppText.semibold,
                    ).merge(AppText.tabular),
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Text(network, style: WalletType.meta(AppColors.textFaint)),
                ],
              ),
            ),
            if (hasAddress)
              Icon(
                Icons.copy_rounded,
                size: AppIcon.sm,
                color: WalletTone.accentSoft,
                semanticLabel: 'Copy address',
              ),
          ],
        ),
      ),
    );
  }

  static String _statusText(String? status) {
    switch (status) {
      case 'disabled':
        return 'On-chain wallet is off';
      case 'error':
        return 'Wallet setup failed. Pull to retry.';
      default:
        return 'Setting up your address…';
    }
  }

  void _copy(BuildContext context, String address) {
    Clipboard.setData(ClipboardData(text: address));
    AppSnackbar.showSuccess(
      context,
      'Address copied.',
      duration: AppSnackbar.longDuration,
    );
  }
}
