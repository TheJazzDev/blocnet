import 'package:flutter/material.dart';
import 'package:blocnet/app/theme.dart';

// Define variants
enum ButtonVariant { small, large }

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.title,
    this.variant = ButtonVariant.large,
    required this.isEnabled,
  });

  final Function() onPressed;
  final String title;
  final bool isEnabled;
  final ButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final double fontSize = variant == ButtonVariant.small ? 12.0 : 16.0;
    final double varticalPadding = variant == ButtonVariant.small ? 8 : 11;
    final double horizontalPadding = variant == ButtonVariant.small ? 20 : 0;

    return Expanded(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Container(
          width: variant != ButtonVariant.small ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            vertical: varticalPadding,
            horizontal: horizontalPadding,
          ),
          decoration: BoxDecoration(
            color: AppColors.darkGrey100,
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            border: Border.all(color: AppColors.darkGrey300),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isEnabled ? AppColors.darkGrey700 : AppColors.darkGrey500,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              fontFamily: 'Geist',
            ),
          ),
        ),
      ),
    );
  }
}
