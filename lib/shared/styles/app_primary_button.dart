import 'package:flutter/material.dart';
import 'package:blocknet/app/theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.title,
    required this.isEnabled,
  });

  final Function()? onPressed;
  final String title;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton(
        onPressed: isEnabled ? onPressed : null,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.primary500 : AppColors.darkGrey200,
            borderRadius: const BorderRadius.all(Radius.circular(25)),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isEnabled ? Colors.black : AppColors.darkGrey500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Geist',
            ),
          ),
        ),
      ),
    );
  }
}
