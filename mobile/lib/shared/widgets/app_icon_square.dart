import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// The faint tint the app puts behind a coloured icon, pill or tag: 12% of
/// [color], and a 35% hairline when [bordered].
BoxDecoration appTintDecoration(
  Color color, {
  BorderRadius radius = AppRadius.sm,
  bool bordered = false,
}) {
  return BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: radius,
    border: bordered ? Border.all(color: color.withValues(alpha: 0.35)) : null,
  );
}

/// A tinted rounded square holding an icon (or a short symbol such as an
/// asset's ticker): the lead of a list row or a stat tile.
///
/// ```dart
/// AppIconSquare(icon: Icons.shield_outlined, color: AppColors.warning500)
/// AppIconSquare(symbol: 'BNP', color: accent, size: 36, bordered: true)
/// ```
class AppIconSquare extends StatelessWidget {
  const AppIconSquare({
    super.key,
    this.icon,
    this.symbol,
    this.color,
    this.size = 32,
    this.iconSize = AppIcon.sm,
    this.bordered = false,
  }) : assert(icon != null || symbol != null);

  final IconData? icon;
  final String? symbol;

  /// Defaults to the live space accent.
  final Color? color;
  final double size;
  final double iconSize;

  /// Adds the 35% hairline. The notification, alert and wallet squares
  /// carry one; list-row squares on a card do not.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primary400;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: appTintDecoration(tint, bordered: bordered),
      child: icon != null
          ? Icon(icon, size: iconSize, color: tint)
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  symbol!,
                  maxLines: 1,
                  style: AppText.caption(tint, weight: AppText.bold),
                ),
              ),
            ),
    );
  }
}
