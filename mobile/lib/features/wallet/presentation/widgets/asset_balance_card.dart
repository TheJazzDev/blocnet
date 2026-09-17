import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_headline.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_pill.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_state_views.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/services/wallet/wallet_visibility_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One asset's balance: ticker square, name and network pill, the amount,
/// and its value line.
class AssetBalanceCard extends StatelessWidget {
  const AssetBalanceCard({super.key, required this.assetCode});

  final String assetCode;

  @override
  Widget build(BuildContext context) {
    final asset = context.watch<WalletStore>().findAsset(assetCode);
    final isHidden = context.watch<WalletVisibilityStore>().isBalanceHidden;
    if (asset == null) return const WalletLoadingCard();

    final valueLine = asset.isPoints
        ? 'Send to any member by @username'
        : isHidden
            ? r'$•••• · Price $••••'
            : isUsdPriceLive(asset.priceSource)
                ? '\$${formatUsd(asset.usdValue)} · Price '
                    '\$${formatUsd(asset.usdPrice, decimals: 4)}'
                : walletUnpricedLabel(asset);

    return WalletCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WalletIconSquare(
                color: assetAccentColor(assetCode),
                symbol: asset.symbol,
                size: 32,
              ),
              const SizedBox(width: AppSpace.md),
              Flexible(
                child: Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WalletType.rowTitle(AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              WalletPill(label: assetBadgeText(asset)),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              isHidden
                  ? '•••••• ${asset.asset}'
                  : '${formatAssetAmount(asset)} ${asset.asset}',
              maxLines: 1,
              style: AppText.display(
                AppColors.textPrimary,
                weight: FontWeight.w800,
              ).merge(AppText.tabular).copyWith(height: 1.1),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(valueLine, style: WalletType.meta(AppColors.textMuted)),
        ],
      ),
    );
  }
}
