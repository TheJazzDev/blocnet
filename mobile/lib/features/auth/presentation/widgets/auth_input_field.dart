import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

/// Styled text field for all auth screens — Web3 dark panel variant.
///
/// Designed to sit inside the frosted-dark form card (#0D1120 bg):
/// - Slightly elevated fill (#131829)
/// - Subtle border at rest, teal glow on focus
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

  static const _fillColor = Color(0xFF131829);
  static const _borderColor = Color(0xFF1E2A45);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofillHints,
      focusNode: focusNode,
      style: TextStyle(
        color: AppColors.darkGrey700,
        fontSize: 14,
        fontFamily: 'Geist',
        fontWeight: FontWeight.w400,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.darkGrey400,
          fontSize: 13,
          fontFamily: 'Geist',
        ),
        floatingLabelStyle: TextStyle(
          color: AppColors.teal400,
          fontSize: 12,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.teal500,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error500, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error500, width: 1.5),
        ),
        errorStyle: TextStyle(
          color: AppColors.error500,
          fontSize: 11,
          fontFamily: 'Geist',
        ),
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
        color: AppColors.darkGrey400,
        size: 18,
      ),
      onPressed: onTap,
    );
  }
}
