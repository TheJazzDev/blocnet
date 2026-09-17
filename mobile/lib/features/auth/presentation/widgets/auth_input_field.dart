import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: color),
        );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofillHints,
      focusNode: focusNode,
      textCapitalization: textCapitalization,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: AppText.body(AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppText.body(AppColors.textFaint),
        floatingLabelStyle:
            AppText.label(AppColors.primary400, weight: AppText.semibold),
        isDense: true,
        filled: true,
        fillColor: AppColors.bgElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md + 2,
          vertical: AppSpace.md + 2,
        ),
        border: border(AppColors.borderMuted),
        enabledBorder: border(AppColors.borderMuted),
        focusedBorder: border(AppColors.primary400),
        errorBorder: border(AppColors.error500),
        focusedErrorBorder: border(AppColors.error500),
        errorStyle: AppText.caption(AppColors.error500),
        errorMaxLines: 2,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Visibility toggle icon button for password fields.
class PasswordVisibilityToggle extends StatelessWidget {
  const PasswordVisibilityToggle({
    super.key,
    required this.isObscured,
    required this.onTap,
  });

  final bool isObscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.textMuted,
        size: AppIcon.md,
      ),
      onPressed: onTap,
    );
  }
}
