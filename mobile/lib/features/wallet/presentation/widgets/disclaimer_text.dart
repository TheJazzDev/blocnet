import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

class DisclaimerText extends StatelessWidget {
  const DisclaimerText({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      "BNT is Blocnet's utility token, not a security or investment. "
      'Wallet features may change.',
      style: AppText.caption(AppColors.textFaint).copyWith(height: 1.5),
    );
  }
}
