import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_pill.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:flutter/material.dart';

/// What the send page does, as a list row in a flat card.
class SendHeaderCard extends StatelessWidget {
  const SendHeaderCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return WalletCard(
      child: Row(
        children: [
          WalletIconSquare(color: WalletTone.accent, icon: icon),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WalletType.rowTitle(AppColors.textPrimary)),
                const SizedBox(height: AppSpace.hair),
                Text(subtitle, style: WalletType.meta(AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
