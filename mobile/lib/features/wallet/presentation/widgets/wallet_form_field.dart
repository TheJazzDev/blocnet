import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Filled input style shared by the wallet send forms.
InputDecoration walletFieldDecoration(String hint, {Widget? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTypography.custom(
      color: AppColors.textFaint,
      size: AppText.bodySize,
      weight: FontWeight.w400,
    ),
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: AppColors.bgElevated,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.mdValue),
      borderSide: BorderSide(color: AppColors.borderSubtle),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.mdValue),
      borderSide: BorderSide(color: AppColors.borderSubtle),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.mdValue),
      borderSide: BorderSide(color: AppColors.teal500),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
  );
}

/// Label + text field, as laid out in the wallet send forms.
class WalletFormField extends StatelessWidget {
  const WalletFormField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.fieldKey,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.custom(
            color: AppColors.textSecondary,
            size: AppText.labelSize,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          style: AppTypography.custom(
            color: AppColors.textSecondary,
            size: AppText.bodySize,
            weight: FontWeight.w400,
          ),
          decoration: walletFieldDecoration(hint),
        ),
      ],
    );
  }
}
