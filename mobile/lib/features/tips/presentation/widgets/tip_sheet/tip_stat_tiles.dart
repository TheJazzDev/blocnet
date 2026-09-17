import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_sheet/tip_sheet_styles.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Balance and fee, two stat tiles side by side.
class TipStatTiles extends StatelessWidget {
  const TipStatTiles({
    super.key,
    required this.balance,
    required this.fee,
    required this.feeNote,
  });

  /// `12.5 BNP`, or `—` while loading.
  final String balance;

  /// `1%`.
  final String fee;

  /// `You pay`, and the minimum when there is one.
  final String feeNote;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _TipStatTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Balance',
              value: balance,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: _TipStatTile(
              icon: Icons.percent_rounded,
              label: 'Fee',
              value: fee,
              note: feeNote,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipStatTile extends StatelessWidget {
  const _TipStatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary500;
    return AppSurface(
      padding: AppSpace.allMd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: AppRadius.sm,
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, size: AppIcon.sm, color: accent),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: tipCaps(AppColors.textFaint)),
                const SizedBox(height: AppSpace.hair),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    AppColors.textPrimary,
                    weight: AppText.bold,
                  ).merge(AppText.tabular),
                ),
                if (note != null)
                  Text(
                    note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption(AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
