import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/widgets/asset_row.dart';
import 'package:blocnet/services/feed_view_mode_store.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssetsSection extends StatelessWidget {
  const AssetsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final viewMode = context.watch<FeedViewModeStore>().mode;
    final snapshot = walletStore.snapshot;
    final assets = snapshot?.assets ?? const <WalletAssetBalance>[];

    if (walletStore.isLoadingSummary && snapshot == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    if (assets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
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
      children: assets.asMap().entries.map((entry) {
        return Column(
          children: [
            AssetRow(asset: entry.value, viewMode: viewMode),
            if (viewMode == FeedViewMode.list && entry.key != assets.length - 1)
              Divider(
                height: 1,
                color: AppColors.borderSubtle.withValues(alpha: 0.8),
              ),
          ],
        );
      }).toList(),
    );
  }
}
