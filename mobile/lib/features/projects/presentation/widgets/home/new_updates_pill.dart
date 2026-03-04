import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class NewUpdatesPill extends StatelessWidget {
  const NewUpdatesPill({
    super.key,
    required this.count,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final int count;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count new updates',
              style: AppTypography.custom(
                color: textColor,
                size: 12,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
