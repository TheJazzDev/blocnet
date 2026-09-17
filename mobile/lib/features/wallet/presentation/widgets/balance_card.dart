import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_headline.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_address_row.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/services/wallet/wallet_visibility_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The wallet headline: total balance, left-aligned in a flat card, with
/// the on-chain address underneath.
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshot = context.watch<WalletStore>().snapshot;
    final visibilityStore = context.watch<WalletVisibilityStore>();
    final headline = WalletHeadline.from(snapshot);
    final isHidden = visibilityStore.isBalanceHidden;

    return WalletCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.xs,
        AppSpace.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: AppIcon.sm,
                color: AppColors.textFaint,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'TOTAL BALANCE',
                  style: WalletType.caps(AppColors.textFaint),
                ),
              ),
              IconButton(
                onPressed: visibilityStore.toggle,
                iconSize: AppIcon.md,
                visualDensity: VisualDensity.compact,
                tooltip: isHidden ? 'Show balances' : 'Hide balances',
                icon: Icon(
                  isHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.md),
            child: _Figures(headline: headline, isHidden: isHidden),
          ),
          const SizedBox(height: AppSpace.sm),
          const Padding(
            padding: EdgeInsets.only(right: AppSpace.sm),
            child: WalletRowDivider(),
          ),
          const WalletAddressRow(),
        ],
      ),
    );
  }
}

class _Figures extends StatelessWidget {
  const _Figures({required this.headline, required this.isHidden});

  final WalletHeadline headline;
  final bool isHidden;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large balances shrink rather than overflow.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            isHidden ? r'$••••••' : headline.amount,
            maxLines: 1,
            style:
                AppText.display(AppColors.textPrimary, weight: FontWeight.w800)
                    .merge(AppText.tabular)
                    .copyWith(height: 1.1),
          ),
        ),
        if (!isHidden && headline.otherHoldings != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            headline.otherHoldings!,
            style: AppText.label(
              AppColors.textSecondary,
              weight: AppText.semibold,
            ),
          ),
        ],
        if (!isHidden && headline.note != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            headline.note!,
            style: AppText.label(AppColors.textFaint),
          ),
        ],
      ],
    );
  }
}
