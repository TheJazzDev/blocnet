import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_headline.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/services/wallet/wallet_visibility_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final visibilityStore = context.watch<WalletVisibilityStore>();
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

    final headline = WalletHeadline.from(snapshot);
    final isBalanceHidden = visibilityStore.isBalanceHidden;
    final balanceText = isBalanceHidden ? '\$••••••' : headline.amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TOTAL BALANCE',
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: AppText.captionSize,
                weight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            IconButton(
              onPressed: visibilityStore.toggle,
              splashRadius: 18,
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              icon: Icon(
                isBalanceHidden
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.textMuted,
              ),
              tooltip: isBalanceHidden ? 'Show balances' : 'Hide balances',
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          balanceText,
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.displayXlSize,
            weight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        if (!isBalanceHidden && headline.otherHoldings != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            headline.otherHoldings!,
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: AppText.labelSize,
              weight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: AppSpace.xs),
        Text(
          'BSC Network',
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: AppText.labelSize,
            weight: FontWeight.w500,
          ),
        ),
        if (!isBalanceHidden && headline.note != null) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            headline.note!,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
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
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    addressText,
                    style: AppTypography.custom(
                      color: AppColors.textSecondary,
                      size: AppText.labelSize,
                      weight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Icon(
                  Icons.copy_rounded,
                  size: AppIcon.sm,
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
