import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final snapshot = walletStore.snapshot;
    final address = snapshot?.walletAddress;
    final status = snapshot?.walletStatus ?? 'provisioning';
    final addressText = address != null && address.isNotEmpty
        ? truncateMiddle(address)
        : (status == 'disabled'
            ? 'Wallet feature disabled'
            : status == 'error'
                ? 'Provisioning error'
                : 'Provisioning wallet...');

    final totalUsd = snapshot?.totalUsdValue ?? '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOTAL BALANCE',
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: 11,
            weight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '\$${formatUsd(totalUsd)}',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 44,
            weight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'BSC Network',
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: 12,
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () {
            if (address == null || address.isEmpty) {
              showWalletToast(
                context,
                message: 'Wallet address is not ready yet.',
                type: WalletToastType.error,
              );
              return;
            }
            Clipboard.setData(ClipboardData(text: address));
            showWalletToast(
              context,
              message: 'Address copied.',
              type: WalletToastType.success,
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    addressText,
                    style: AppTypography.custom(
                      color: AppColors.textSecondary,
                      size: 12,
                      weight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: AppColors.teal400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
