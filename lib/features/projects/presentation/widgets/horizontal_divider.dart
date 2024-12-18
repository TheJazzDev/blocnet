import 'package:blocknet/app/theme.dart';
import 'package:flutter/material.dart';

class CustomHorizontalDivider extends StatelessWidget {
  const CustomHorizontalDivider({
    required this.margin,
    super.key,
  });

  final double margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: margin),
      decoration: BoxDecoration(
        color: AppColors.darkGrey200,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
    );
  }
}
