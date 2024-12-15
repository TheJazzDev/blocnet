import 'package:flutter/material.dart';
import 'package:blocknet/app/app_theme.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.title,
    required this.isEnabled,
  });

  final Function() onPressed;
  final String title;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.darkGrey100,
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            border: Border.all(color: AppColors.darkGrey300),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                color:
                    isEnabled ? AppColors.darkGrey700 : AppColors.darkGrey500,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Geist'),
          ),
        ),
      ),
    );
  }
}
