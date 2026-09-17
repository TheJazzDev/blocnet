import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_pill.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_activity_rows.dart';
import 'package:flutter/material.dart';

/// One transaction or withdrawal as a list row: direction square, title
/// with its status pill, counterparty and date, signed amount.
class WalletActivityRow extends StatelessWidget {
  const WalletActivityRow({super.key, required this.item, this.onTap});

  final WalletActivityItem item;
  final VoidCallback? onTap;

  Color get _tone => item.isIncoming
      ? WalletTone.incoming
      : item.isOutgoing
          ? WalletTone.accent
          : AppColors.textMuted;

  @override
  Widget build(BuildContext context) {
    final badgeColor = item.badgeColor;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: AppSpace.row,
        child: Row(
          children: [
            WalletIconSquare(color: _tone, icon: item.icon, size: 34),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WalletType.rowTitle(AppColors.textPrimary),
                        ),
                      ),
                      if (item.badgeLabel != null && badgeColor != null) ...[
                        const SizedBox(width: AppSpace.sm),
                        WalletPill(label: item.badgeLabel!, color: badgeColor),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WalletType.meta(AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  item.amountLabel,
                  maxLines: 1,
                  style: AppText.label(item.amountColor, weight: AppText.bold)
                      .merge(AppText.tabular),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
