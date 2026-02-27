import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.9), width: 0.8),
      ),
      child: Text(
        label,
        style: AppTypography.custom(
          color: color,
          size: 9,
          weight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
