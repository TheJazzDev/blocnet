import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// The wallet's colours and type, all drawn from [AppColors] / [AppText].
///
/// The accent follows the space at runtime (cyan in Hunter space, blue in
/// User space), so it is read on every call rather than cached.
class WalletTone {
  const WalletTone._();

  static Color get accent => AppColors.primary500;
  static Color get accentSoft => AppColors.primary400;

  /// Text on a filled [accent]: black on cyan, white on blue.
  static Color get onAccent =>
      accent.computeLuminance() > 0.4 ? Colors.black : Colors.white;

  static Color get incoming => AppColors.successColor;
  static Color get pending => AppColors.warning500;
  static const Color failed = AppColors.tagWarning;
}

class WalletType {
  const WalletType._();

  /// 10px letter-spaced caps: card and section labels, pills.
  static TextStyle caps(Color color, {double tracking = 1.0}) =>
      AppText.caption(color, weight: AppText.bold)
          .copyWith(letterSpacing: tracking);

  /// 14/700 row titles.
  static TextStyle rowTitle(Color color) =>
      AppText.body(color, weight: AppText.bold);

  /// 12px muted second lines.
  static TextStyle meta(Color color) => AppText.label(color);
}

/// Flat wallet card: surface ground, 1px subtle edge, [AppRadius.md].
BoxDecoration walletCardDecoration({Color? edge}) {
  return BoxDecoration(
    color: AppColors.bgSurface,
    borderRadius: AppRadius.md,
    border: Border.all(color: edge ?? AppColors.borderSubtle),
  );
}

/// A flat bordered card with the standard interior.
class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.child,
    this.padding = AppSpace.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: walletCardDecoration(),
      child: child,
    );
  }
}
