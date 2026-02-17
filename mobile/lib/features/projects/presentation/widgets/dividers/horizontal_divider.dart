import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

class CustomHorizontalDivider extends StatelessWidget {
  const CustomHorizontalDivider({required this.margin, super.key});

  final double margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: margin),
      color: AppColors.borderSubtle,
    );
  }
}
