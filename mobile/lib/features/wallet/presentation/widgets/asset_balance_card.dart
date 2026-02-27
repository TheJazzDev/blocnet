import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssetBalanceCard extends StatelessWidget {
  const AssetBalanceCard({super.key, required this.assetCode});

  final String assetCode;

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final asset = walletStore.findAsset(assetCode);
    final accent = assetAccentColor(assetCode);

    if (asset == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          'Loading $assetCode balance...',
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: 13,
            weight: FontWeight.w400,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            AppColors.primary500.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                asset.name,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 17,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  assetBadgeText(asset),
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 10,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${asset.available} ${asset.asset}',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 32,
              weight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${formatUsd(asset.usdValue)} • Price \$${formatUsd(asset.usdPrice, decimals: 4)}',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 12,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
