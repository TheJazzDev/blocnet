import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_pill.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:flutter/material.dart';

/// One-time tip on the wallet tab, dismissible.
class WalletOnboardingBanner extends StatelessWidget {
  const WalletOnboardingBanner({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return WalletCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.xs,
        AppSpace.md,
      ),
      child: Row(
        children: [
          WalletIconSquare(
            color: WalletTone.accent,
            icon: Icons.lightbulb_outline_rounded,
            size: 32,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Getting started',
                  style: WalletType.rowTitle(AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  'Receive shows your address. Send moves BNP or tokens.',
                  style: WalletType.meta(AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: 'Dismiss',
            iconSize: AppIcon.md,
            icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
