import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:flutter/material.dart';

/// Flat Mine card ground: `#101012` with a 1 px inset edge.
BoxDecoration mineTileDecoration({
  Color ground = MinePalette.card,
  Color edge = MinePalette.tileEdge,
  BorderRadius radius = AppRadius.md,
}) {
  return BoxDecoration(
    color: ground,
    borderRadius: radius,
    border: Border.all(color: edge),
  );
}

/// `BALANCE` style section label with an icon and an optional right label.
class MineSectionHeader extends StatelessWidget {
  const MineSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.topPadding = AppSpace.xl,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final caps = AppText.caption(MinePalette.caption, weight: AppText.bold)
        .copyWith(letterSpacing: 1.5);
    final row = Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        topPadding,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIcon.sm, color: MinePalette.quiet),
          const SizedBox(width: AppSpace.sm),
          Text(title.toUpperCase(), style: caps),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!.toUpperCase(),
              style: caps.copyWith(
                color: MinePalette.quiet,
                letterSpacing: 0.7,
              ),
            ),
          if (onTap != null) ...[
            const SizedBox(width: AppSpace.xs),
            const Icon(
              Icons.chevron_right_rounded,
              size: AppIcon.sm,
              color: MinePalette.quiet,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return Semantics(header: true, child: row);
    return Semantics(
      header: true,
      button: true,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// Balance: big number, the conversion line, and the Wallet link.
class MineBalanceCard extends StatelessWidget {
  const MineBalanceCard({
    super.key,
    required this.balance,
    required this.onOpenWallet,
  });

  final int balance;
  final VoidCallback onOpenWallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.lg,
        0,
      ),
      decoration: mineTileDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Large balances shrink rather than overflow.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    MineFormat.points(balance),
                    style: AppText.display(MinePalette.white)
                        .merge(AppText.tabular)
                        .copyWith(height: 1),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text('BNP', style: AppText.body(MinePalette.muted)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Converts to BNT at launch.',
            style: AppText.label(MinePalette.faint),
          ),
          const SizedBox(height: AppSpace.md),
          const Divider(height: 1, thickness: 1, color: MinePalette.divider),
          InkWell(
            onTap: onOpenWallet,
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: AppIcon.sm,
                    color: MinePalette.accent,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    'View in Wallet',
                    style: AppText.label(
                      MinePalette.accent,
                      weight: AppText.semibold,
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: AppIcon.sm,
                    color: MinePalette.accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A one-line card that opens a sub-screen: icon, title over subtitle, chevron.
class MineLinkRow extends StatelessWidget {
  const MineLinkRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.md,
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.lg,
            ),
            decoration: mineTileDecoration(),
            child: Row(
              children: [
                Icon(icon, size: AppIcon.md, color: MinePalette.caption),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.body(
                          MinePalette.white,
                          weight: AppText.semibold,
                        ),
                      ),
                      const SizedBox(height: AppSpace.hair),
                      Text(subtitle, style: AppText.label(MinePalette.faint)),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: AppIcon.sm,
                  color: MinePalette.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
