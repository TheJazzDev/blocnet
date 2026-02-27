import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: AppTypography.custom(
          color: AppColors.textFaint,
          size: 10,
          weight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
