import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// A labelled text input.
///
/// The app has 36 raw `TextField`/`TextFormField`s, each restating the same
/// border, fill and focus colours. This fixes those and adds the two things
/// the hand-rolled ones usually skip: a real error line, and a label wired to
/// the field so screen readers announce it.
///
/// ```dart
/// AppTextField(
///   label: 'Moderation note',
///   hint: 'Why is this update being rejected?',
///   controller: noteController,
///   maxLines: 4,
/// )
/// ```
class AppTextField extends StatelessWidget {
  const AppTextField({
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffix,
    this.autofocus = false,
    super.key,
  });

  final String? label;
  final String? hint;
  final String? helper;

  /// Non-null paints the error border and shows the message. Prefer a sentence
  /// that says how to fix it over a restatement of the rule.
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final borderColor =
        hasError ? AppColors.error500 : AppColors.borderSubtle;

    OutlineInputBorder border(Color c, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: c, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppText.label(
              AppColors.textSecondary,
              weight: AppText.medium,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          autofocus: autofocus,
          style: AppText.body(AppColors.textPrimary),
          cursorColor: AppColors.primary500,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body(AppColors.textFaint),
            filled: true,
            fillColor: enabled ? AppColors.bgSurface : AppColors.bgElevated,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.md,
            ),
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: AppIcon.sm, color: AppColors.textFaint),
            suffixIcon: suffix,
            counterText: '',
            enabledBorder: border(borderColor),
            disabledBorder: border(AppColors.borderSubtle),
            focusedBorder: border(
              hasError ? AppColors.error500 : AppColors.primary500,
              width: 1.5,
            ),
            border: border(borderColor),
          ),
        ),
        if (hasError || helper != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            errorText ?? helper!,
            style: AppText.caption(
              hasError ? AppColors.error500 : AppColors.textFaint,
            ),
          ),
        ],
      ],
    );
  }
}
