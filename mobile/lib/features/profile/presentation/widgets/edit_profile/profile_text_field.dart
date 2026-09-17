import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Flat bordered text field used by the profile forms.
class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.controller,
    this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
  });

  final TextEditingController controller;
  final String? hint;
  final int minLines;
  final int maxLines;
  final int? maxLength;

  static OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: AppText.body(AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(AppColors.textFaint),
        counterStyle: AppText.caption(AppColors.textFaint),
        filled: true,
        fillColor: AppColors.bgSurface,
        border: _border(AppColors.borderSubtle),
        enabledBorder: _border(AppColors.borderSubtle),
        focusedBorder: _border(AppColors.primary400, 1.4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
      ),
    );
  }
}
