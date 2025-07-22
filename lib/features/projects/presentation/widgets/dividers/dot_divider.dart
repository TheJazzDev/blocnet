import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

class DotDivider extends StatelessWidget {
  const DotDivider(this.margin, {super.key});

  final double margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(margin),
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.darkGrey200,
        shape: BoxShape.circle,
      ),
    );
  }
}
