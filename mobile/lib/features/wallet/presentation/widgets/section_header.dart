import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.actionLabel,
    this.actionRoute,
  });

  final String label;
  final String? actionLabel;
  final String? actionRoute;

  @override
  Widget build(BuildContext context) {
    final canShowAction = actionLabel != null && actionRoute != null;

    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: 11,
              weight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ),
        if (canShowAction)
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed(actionRoute!),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primary500,
            ),
            child: Text(
              actionLabel!,
              style: AppTypography.custom(
                color: AppColors.primary500,
                size: 11,
                weight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
