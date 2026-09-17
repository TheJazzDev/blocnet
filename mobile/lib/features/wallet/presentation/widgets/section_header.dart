import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:flutter/material.dart';

/// Section label: small icon, 10px bold caps in the faint text colour, and
/// an optional accent action on the right ("View all").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.icon,
    this.actionLabel,
    this.actionRoute,
  });

  final String label;
  final IconData? icon;
  final String? actionLabel;
  final String? actionRoute;

  @override
  Widget build(BuildContext context) {
    final canShowAction = actionLabel != null && actionRoute != null;

    return Semantics(
      header: true,
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppIcon.sm, color: AppColors.textFaint),
              const SizedBox(width: AppSpace.sm),
            ],
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WalletType.caps(AppColors.textFaint),
              ),
            ),
            if (canShowAction)
              InkWell(
                borderRadius: AppRadius.sm,
                onTap: () => Navigator.of(context).pushNamed(actionRoute!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.xs,
                    vertical: AppSpace.xs,
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppText.label(
                      WalletTone.accentSoft,
                      weight: AppText.bold,
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
