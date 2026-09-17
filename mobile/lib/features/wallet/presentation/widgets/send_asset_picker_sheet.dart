import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/assets_section.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_pill.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:flutter/material.dart';

/// Bottom sheet listing the wallet's assets; pops the chosen asset code.
class SendAssetPickerSheet extends StatelessWidget {
  const SendAssetPickerSheet({super.key, required this.assets});

  final List<WalletAssetBalance> assets;

  @override
  Widget build(BuildContext context) {
    final ordered = walletAssetsPointsFirst(assets);
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgBase,
          borderRadius: AppRadius.sheet,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          AppSpace.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.borderMuted,
                  borderRadius: AppRadius.full,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text('Send which asset?',
                style: AppText.title(AppColors.textPrimary)),
            const SizedBox(height: AppSpace.md),
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: walletCardDecoration(),
                  child: Column(
                    children: [
                      for (var i = 0; i < ordered.length; i++) ...[
                        if (i > 0) const WalletRowDivider(),
                        _AssetOption(asset: ordered[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetOption extends StatelessWidget {
  const _AssetOption({required this.asset});

  final WalletAssetBalance asset;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(asset.asset),
      child: Padding(
        padding: AppSpace.row,
        child: Row(
          children: [
            WalletIconSquare(
              color: assetAccentColor(asset.asset),
              symbol: asset.symbol,
              size: 32,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WalletType.rowTitle(AppColors.textPrimary),
                  ),
                  Text(asset.asset,
                      style: WalletType.meta(AppColors.textMuted)),
                ],
              ),
            ),
            Text(
              formatAssetAmount(asset),
              style: AppText.label(
                AppColors.textSecondary,
                weight: AppText.semibold,
              ).merge(AppText.tabular),
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
