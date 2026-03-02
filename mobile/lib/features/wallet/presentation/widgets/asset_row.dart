import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:flutter/material.dart';

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
    final isCardMode = viewMode == FeedViewMode.card;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.walletAssetDetail,
          arguments: {'assetCode': asset.asset},
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: isCardMode ? 10 : 0),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                borderRadius: BorderRadius.circular(14),
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
                  size: 11,
                  weight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        asset.asset,
                        style: AppTypography.custom(
                          color: AppColors.textFaint,
                          size: 11,
                          weight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          assetBadgeText(asset),
                          style: AppTypography.custom(
                            color: accent,
                            size: 8,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatTokenAmount(asset.available),
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${formatUsd(asset.usdValue)}',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 12,
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
