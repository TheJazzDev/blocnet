import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:flutter/material.dart';

/// Bottom sheet listing the wallet's assets; pops the chosen asset code.
class SendAssetPickerSheet extends StatelessWidget {
  const SendAssetPickerSheet({super.key, required this.assets});

  final List<WalletAssetBalance> assets;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMuted,
                  borderRadius: BorderRadius.circular(AppRadius.fullValue),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              'Select Asset To Send',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: AppText.subtitleSize,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            ...assets.map((asset) => _AssetOption(asset: asset)),
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
    final accent = assetAccentColor(asset.asset);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.mdValue),
      onTap: () => Navigator.of(context).pop(asset.asset),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.14),
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
              child: Text(
                '${asset.name} (${asset.asset})',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.labelSize,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              formatAssetAmount(asset),
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.labelSize,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
