import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// A label above a composer field.
class ComposerFieldLabel extends StatelessWidget {
  const ComposerFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.custom(
        color: AppColors.textMuted,
        size: AppText.labelSize,
        weight: FontWeight.w500,
      ),
    );
  }
}

/// The composer's text style for field values.
TextStyle composerValueStyle() => AppTypography.custom(
      color: AppColors.textSecondary,
      size: AppText.bodySize,
      weight: FontWeight.w400,
    );

/// The shared input decoration for composer fields.
InputDecoration composerFieldDecoration({String? hintText}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTypography.custom(
      color: AppColors.textFaint,
      size: AppText.bodySize,
      weight: FontWeight.w400,
    ),
    filled: true,
    fillColor: AppColors.bgElevated,
    border: border(AppColors.borderSubtle),
    enabledBorder: border(AppColors.borderSubtle),
    disabledBorder: border(AppColors.borderSubtle),
    focusedBorder: border(AppColors.teal500),
    errorBorder: border(AppColors.error500),
    focusedErrorBorder: border(AppColors.error500),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpace.lg,
      vertical: AppSpace.md,
    ),
  );
}
