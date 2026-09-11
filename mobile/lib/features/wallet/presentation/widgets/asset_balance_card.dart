import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/services/wallet/wallet_visibility_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssetBalanceCard extends StatelessWidget {
  const AssetBalanceCard({
    super.key,
    required this.assetCode,
    required this.mode,
  });

  final String assetCode;
  final FeedViewMode mode;

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final isBalanceHidden =
        context.watch<WalletVisibilityStore>().isBalanceHidden;
    final asset = walletStore.findAsset(assetCode);
    final accent = assetAccentColor(assetCode);
    final isCardMode = mode == FeedViewMode.card;

    if (asset == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        child: Text(
          'Loading $assetCode balance...',
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: AppText.bodySize,
            weight: FontWeight.w400,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md, horizontal: AppSpace.md),
      decoration: isCardMode
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.18),
                  AppColors.primary500.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lgValue),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                asset.name,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.subtitleSize,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
                decoration: BoxDecoration(
                  color:
                      (isCardMode ? AppColors.bgSurface : AppColors.bgElevated)
                          .withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadius.lgValue),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  assetBadgeText(asset),
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.captionSize,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            isBalanceHidden
                ? '•••••• ${asset.asset}'
                : '${formatTokenAmount(asset.available)} ${asset.asset}',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.displaySize,
              weight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            isBalanceHidden
                ? '\$•••• • Price \$••••'
                : (isUsdPriceLive(asset.priceSource)
                    ? '\$${formatUsd(asset.usdValue)} • Price \$${formatUsd(asset.usdPrice, decimals: 4)}'
                    : 'Pre-launch · no market value yet'),
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.labelSize,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
