import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:flutter/material.dart';

/// One option of the in-Blocnet / on-chain choice on the token send page.
/// The picked one carries an accent edge and a faint accent tint.
class SendModeTile extends StatelessWidget {
  const SendModeTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = WalletTone.accent;
    return Semantics(
      button: true,
      selected: isActive,
      child: InkWell(
        borderRadius: AppRadius.md,
        onTap: onTap,
        child: Container(
          padding: AppSpace.allMd,
          decoration: BoxDecoration(
            color:
                isActive ? accent.withValues(alpha: 0.08) : AppColors.bgSurface,
            borderRadius: AppRadius.md,
            border: Border.all(
              color: isActive
                  ? accent.withValues(alpha: 0.5)
                  : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppIcon.sm,
                color: isActive ? WalletTone.accentSoft : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(
                        AppColors.textPrimary,
                        weight: AppText.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption(AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
