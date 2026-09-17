import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/wallet/presentation/widgets/parts/wallet_style.dart';
import 'package:flutter/material.dart';

/// The wallet's 44px button: filled accent, or dark outlined.
class WalletButton extends StatelessWidget {
  const WalletButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
  });

  const WalletButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : filled = false;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: AppRadius.md);
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final textStyle = AppText.body(Colors.white, weight: AppText.bold);
    const size = Size.fromHeight(44);
    const padding = EdgeInsets.symmetric(horizontal: AppSpace.md);

    if (filled) {
      final style = FilledButton.styleFrom(
        backgroundColor: WalletTone.accent,
        foregroundColor: WalletTone.onAccent,
        minimumSize: size,
        padding: padding,
        shape: shape,
        textStyle: textStyle,
      );
      return icon == null
          ? FilledButton(onPressed: onPressed, style: style, child: text)
          : FilledButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: AppIcon.sm),
              label: text,
            );
    }

    final style = OutlinedButton.styleFrom(
      backgroundColor: AppColors.bgElevated,
      foregroundColor: AppColors.textPrimary,
      minimumSize: size,
      padding: padding,
      side: const BorderSide(color: AppColors.borderMuted),
      shape: shape,
      textStyle: textStyle,
    );
    return icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: text)
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: AppIcon.sm),
            label: text,
          );
  }
}
