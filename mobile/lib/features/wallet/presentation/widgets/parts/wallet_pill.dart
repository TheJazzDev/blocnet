import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:flutter/material.dart';

/// Outlined pill: a faint tint of [color], a coloured hairline and coloured
/// caps — the old feed's `HIGH` / `HUNTER` pills. Without a colour it is a
/// neutral grey pill.
class WalletPill extends StatelessWidget {
  const WalletPill({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: tint == null
            ? AppColors.bgElevated
            : tint.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(
          color: tint == null
              ? AppColors.borderMuted
              : tint.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        style: WalletType.caps(tint ?? AppColors.textMuted, tracking: 0.6),
      ),
    );
  }
}

/// Tinted square holding an icon or a short symbol (an asset's ticker).
class WalletIconSquare extends StatelessWidget {
  const WalletIconSquare({
    super.key,
    required this.color,
    this.icon,
    this.symbol,
    this.size = 36,
  }) : assert(icon != null || symbol != null);

  final Color color;
  final IconData? icon;
  final String? symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: icon != null
          ? Icon(icon, size: AppIcon.sm, color: color)
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  symbol!,
                  maxLines: 1,
                  style: AppText.caption(color, weight: FontWeight.w800),
                ),
              ),
            ),
    );
  }
}
