import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SwapFlowScreen extends StatelessWidget {
  const SwapFlowScreen({
    super.key,
    required this.initialAsset,
  });

  final String initialAsset;

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final assets = walletStore.supportedAssets;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          'Swap',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 18,
            weight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'Swap flow is in rollout. Select an asset below to review balances before swapping.',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Assets',
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: 10,
                weight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: assets.length,
                separatorBuilder: (_, __) =>
                    Divider(color: AppColors.borderSubtle, height: 1),
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: assetAccentColor(asset).withValues(
                        alpha: 0.2,
                      ),
                      child: Text(
                        asset,
                        style: AppTypography.custom(
                          color: AppColors.textPrimary,
                          size: 10,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      asset,
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: 13,
                        weight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      asset == initialAsset
                          ? 'Default swap asset'
                          : 'Supported asset',
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 11,
                        weight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textFaint,
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.walletAssetDetail,
                        arguments: {'assetCode': asset},
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
