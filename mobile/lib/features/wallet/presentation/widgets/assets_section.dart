import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/widgets/asset_row.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssetsSection extends StatelessWidget {
  const AssetsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final snapshot = walletStore.snapshot;
    final assets = snapshot?.assets ?? const <WalletAssetBalance>[];

    if (walletStore.isLoadingSummary && snapshot == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.teal400,
            strokeWidth: 2.2,
          ),
        ),
      );
    }

    if (assets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          'No assets available yet.',
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: 12,
            weight: FontWeight.w400,
          ),
        ),
      );
    }

    return Column(
      children: assets
          .map((asset) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AssetRow(asset: asset),
              ))
          .toList(),
    );
  }
}
