import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Moderation's type, on the app's own scale.
class ModText {
  const ModText._();

  /// 10px bold letter-spaced caps: section and field labels.
  static TextStyle caps(Color color) =>
      AppText.caption(color, weight: AppText.bold).copyWith(letterSpacing: 1.0);

  /// 12px secondary lines.
  static TextStyle meta(Color color) => AppText.label(color);

  /// 14px reading text.
  static TextStyle body(Color color) => AppText.body(color);

  /// 14px bold row and card titles.
  static TextStyle rowTitle(Color color) =>
      AppText.body(color, weight: AppText.bold).copyWith(height: 1.35);
}

/// `FIELD LABEL` above an input.
class ModFieldLabel extends StatelessWidget {
  const ModFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Text(text.toUpperCase(), style: ModText.caps(AppColors.textFaint)),
    );
  }
}

/// A 1px divider inside a card.
class ModHairline extends StatelessWidget {
  const ModHairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.only(left: indent),
      color: AppColors.borderSubtle,
    );
  }
}

/// The dark input every moderation form uses.
InputDecoration modInputDecoration({String? hint, String? label}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    hintText: hint,
    labelText: label,
    hintStyle: AppText.body(AppColors.textFaint),
    labelStyle: AppText.label(AppColors.textMuted),
    filled: true,
    fillColor: AppColors.bgBase,
    isDense: true,
    counterStyle: AppText.caption(AppColors.textFaint),
    contentPadding: AppSpace.allMd,
    border: border(AppColors.borderSubtle),
    enabledBorder: border(AppColors.borderSubtle),
    focusedBorder: border(AppColors.borderMuted),
  );
}
