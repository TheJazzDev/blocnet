import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Flat Mine card: surface ground, 1 px subtle edge, [AppRadius.lg].
BoxDecoration mineTileDecoration({
  Color ground = MinePalette.card,
  Color edge = MinePalette.edge,
  BorderRadius radius = AppRadius.lg,
}) {
  return BoxDecoration(
    color: ground,
    borderRadius: radius,
    border: Border.all(color: edge),
  );
}

/// Old `GLOBAL LEADERBOARD` label: small caps, and the right label in an
/// accent chip.
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
    final row = Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        topPadding,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIcon.sm, color: MinePalette.faint),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption(MinePalette.faint, weight: AppText.bold)
                  .copyWith(letterSpacing: 1.2),
            ),
          ),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.hair,
              ),
              decoration: BoxDecoration(
                color: MinePalette.accent.withValues(alpha: 0.12),
                borderRadius: AppRadius.full,
              ),
              child: Text(
                trailing!.toUpperCase(),
                style: AppText.caption(
                  MinePalette.accentSoft,
                  weight: AppText.bold,
                ),
              ),
            ),
          if (onTap != null) ...[
            const SizedBox(width: AppSpace.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: AppIcon.md,
              color: MinePalette.faint,
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

/// Balance: the number, the conversion line, and the Wallet link.
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
                    style: AppText.display(MinePalette.text)
                        .merge(AppText.tabular)
                        .copyWith(height: 1),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                'BNP',
                style: AppText.subtitle(MinePalette.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Converts to BNT at launch.',
            style: AppText.label(MinePalette.faint),
          ),
          const SizedBox(height: AppSpace.md),
          const Divider(height: 1, thickness: 1, color: MinePalette.edge),
          SizedBox(
            height: 48,
            child: AppListRow(
              icon: Icons.account_balance_wallet_outlined,
              plainIcon: true,
              title: 'View in Wallet',
              padding: EdgeInsets.zero,
              onTap: onOpenWallet,
            ),
          ),
        ],
      ),
    );
  }
}

/// A card that opens a sub-screen: the shared list row, with the Mine's
/// bare accent icon, alone in a row group.
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
      child: AppRowGroup(
        children: [
          AppListRow(
            icon: icon,
            plainIcon: true,
            title: title,
            subtitle: subtitle,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
