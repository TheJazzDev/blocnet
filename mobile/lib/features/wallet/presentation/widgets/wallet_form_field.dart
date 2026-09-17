import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Filled input style shared by the wallet send forms.
InputDecoration walletFieldDecoration(String hint, {Widget? prefixIcon}) {
  OutlineInputBorder edge(Color color) => OutlineInputBorder(
        borderRadius: AppRadius.sm,
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: AppText.body(AppColors.textFaint),
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: AppColors.bgElevated,
    isDense: true,
    border: edge(AppColors.borderSubtle),
    enabledBorder: edge(AppColors.borderSubtle),
    focusedBorder: edge(AppColors.primary500),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpace.md,
      vertical: 12,
    ),
  );
}

/// Input text style of the wallet send forms.
TextStyle get walletFieldTextStyle => AppText.body(AppColors.textPrimary);

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
          style:
              AppText.label(AppColors.textSecondary, weight: AppText.semibold),
        ),
        const SizedBox(height: AppSpace.xs),
        TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          style: walletFieldTextStyle,
          decoration: walletFieldDecoration(hint),
        ),
      ],
    );
  }
}
