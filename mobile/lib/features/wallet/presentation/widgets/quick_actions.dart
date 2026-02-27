import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/wallet/presentation/pages/swap_flow_screen.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';
import 'package:blocnet/features/wallet/presentation/widgets/quick_action_button.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final defaultAsset = walletStore.supportedAssets.isEmpty
        ? 'BNT'
        : walletStore.supportedAssets.first;

    return Row(
      children: [
        Expanded(
          child: QuickActionButton(
            icon: Icons.arrow_downward_rounded,
            label: 'Receive',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.successColor,
                AppColors.successColor.withValues(alpha: 0.7),
              ],
            ),
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.walletAssetDetail,
                arguments: {'assetCode': defaultAsset},
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: QuickActionButton(
            icon: Icons.arrow_upward_rounded,
            label: 'Send',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary500,
                AppColors.primary600,
              ],
            ),
            onTap: () {
              openSendFlow(context, assetCode: defaultAsset);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: QuickActionButton(
            icon: Icons.swap_horiz_rounded,
            label: 'Swap',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.teal500,
                AppColors.teal400,
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SwapFlowScreen(
                    initialAsset: defaultAsset,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
