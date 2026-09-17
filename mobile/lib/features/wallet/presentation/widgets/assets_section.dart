import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/widgets/asset_row.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_state_views.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The wallet's assets as rows in one card. BNP leads: it is what members
/// hold and move day to day.
class AssetsSection extends StatelessWidget {
  const AssetsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final snapshot = walletStore.snapshot;
    final assets = walletAssetsPointsFirst(
      snapshot?.assets ?? const <WalletAssetBalance>[],
    );

    if (walletStore.isLoadingSummary && snapshot == null) {
      return const WalletLoadingCard();
    }

    if (assets.isEmpty) {
      return const WalletNoticeCard(
        icon: Icons.token_outlined,
        message: 'No assets yet.',
      );
    }

    return AppRowGroup(
      children: [
        for (final asset in assets) AssetRow(asset: asset),
      ],
    );
  }
}

/// [assets] with points first, otherwise in the server's order.
List<WalletAssetBalance> walletAssetsPointsFirst(
  List<WalletAssetBalance> assets,
) {
  return [
    ...assets.where((a) => a.isPoints),
    ...assets.where((a) => !a.isPoints),
  ];
}
