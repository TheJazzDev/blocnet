import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:flutter/material.dart';

/// A card-sized spinner while a wallet list has nothing to show yet.
class WalletLoadingCard extends StatelessWidget {
  const WalletLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return WalletCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: WalletTone.accent,
          ),
        ),
      ),
    );
  }
}

/// A left-aligned one-line card: faint icon, bold message, optional
/// muted detail. Used for empty lists and availability notes.
class WalletNoticeCard extends StatelessWidget {
  const WalletNoticeCard({
    super.key,
    required this.icon,
    required this.message,
    this.detail,
    this.iconColor,
  });

  final IconData icon;
  final String message;
  final String? detail;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return WalletCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIcon.md, color: iconColor ?? AppColors.textFaint),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppText.body(
                    AppColors.textSecondary,
                    weight: AppText.semibold,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: AppSpace.hair),
                  Text(detail!, style: WalletType.meta(AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
