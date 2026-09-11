import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class ProfileRoleChip extends StatelessWidget {
  const ProfileRoleChip({
    super.key,
    required this.label,
    required this.textColor,
    required this.borderColor,
    required this.backgroundColor,
  });

  final String label;
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.fullValue),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: AppTypography.custom(
          color: textColor,
          size: AppText.captionSize,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}
