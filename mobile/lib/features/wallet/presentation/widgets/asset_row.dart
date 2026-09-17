import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_headline.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_pill.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:blocnet/services/wallet/wallet_visibility_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One asset as a list row: ticker square, name over code and network pill,
/// amount over its USD value (or why it has none), chevron.
class AssetRow extends StatelessWidget {
  const AssetRow({super.key, required this.asset});

  final WalletAssetBalance asset;

  @override
  Widget build(BuildContext context) {
    final accent = assetAccentColor(asset.asset);
    final isHidden = context.watch<WalletVisibilityStore>().isBalanceHidden;
    final amountText = isHidden ? '••••••' : formatAssetAmount(asset);
    final usdText = isHidden
        ? r'$••••'
        : (isUsdPriceLive(asset.priceSource)
            ? '\$${formatUsd(asset.usdValue)}'
            : walletUnpricedLabel(asset));

    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.walletAssetDetail,
        arguments: {'assetCode': asset.asset},
      ),
      child: Padding(
        padding: AppSpace.row,
        child: Row(
          children: [
            WalletIconSquare(color: accent, symbol: asset.symbol),
            const SizedBox(width: AppSpace.md),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WalletType.rowTitle(AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Row(
                    children: [
                      Text(
                        asset.asset,
                        style: WalletType.meta(AppColors.textMuted),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Flexible(
                        child: WalletPill(label: assetBadgeText(asset)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Large amounts shrink rather than lose digits.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      amountText,
                      maxLines: 1,
                      style: WalletType.rowTitle(AppColors.textPrimary)
                          .merge(AppText.tabular),
                    ),
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Text(
                    usdText,
                    maxLines: 1,
                    style: WalletType.meta(AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: AppIcon.md,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}
