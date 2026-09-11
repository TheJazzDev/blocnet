import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/services/wallet/wallet_visibility_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssetRow extends StatelessWidget {
  const AssetRow({
    super.key,
    required this.asset,
    required this.viewMode,
  });

  final WalletAssetBalance asset;
  final FeedViewMode viewMode;

  @override
  Widget build(BuildContext context) {
    final accent = assetAccentColor(asset.asset);
    final isBalanceHidden =
        context.watch<WalletVisibilityStore>().isBalanceHidden;
    final isCardMode = viewMode == FeedViewMode.card;
    final amountText =
        isBalanceHidden ? '••••••' : formatTokenAmount(asset.available);
    final usdText = isBalanceHidden
        ? '\$••••'
        : (isUsdPriceLive(asset.priceSource)
            ? '\$${formatUsd(asset.usdValue)}'
            : 'Pre-launch');
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.mdValue),
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.walletAssetDetail,
          arguments: {'assetCode': asset.asset},
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: isCardMode ? 10 : 0),
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md, horizontal: AppSpace.md),
        decoration: isCardMode
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.bgSurface,
                    AppColors.bgSurface.withValues(alpha: 0.82),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lgValue),
                border: Border.all(
                  color: AppColors.borderSubtle.withValues(alpha: 0.75),
                  width: 1.2,
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.25),
                    accent.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                asset.symbol,
                style: AppTypography.custom(
                  color: accent,
                  size: AppText.captionSize,
                  weight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.bodySize,
                      weight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Row(
                    children: [
                      Text(
                        asset.asset,
                        style: AppTypography.custom(
                          color: AppColors.textFaint,
                          size: AppText.captionSize,
                          weight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.xs,
                          vertical: AppSpace.hair,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.smValue),
                        ),
                        child: Text(
                          assetBadgeText(asset),
                          style: AppTypography.custom(
                            color: accent,
                            size: AppText.captionSize,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountText,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: AppText.bodySize,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  usdText,
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.labelSize,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
