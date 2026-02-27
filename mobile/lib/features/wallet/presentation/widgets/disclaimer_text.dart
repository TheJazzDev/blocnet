import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class DisclaimerText extends StatelessWidget {
  const DisclaimerText({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      "BNT is Blocnet's native utility token. It is not a security or financial instrument. "
      'All wallet features are under active development and subject to change.',
      textAlign: TextAlign.center,
      style: AppTypography.custom(
        color: AppColors.textFaint,
        size: 10,
        weight: FontWeight.w400,
        height: 1.6,
      ),
    );
  }
}
