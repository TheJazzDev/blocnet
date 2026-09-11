import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

class EmptyActivityCard extends StatelessWidget {
  const EmptyActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Text(
        'No public posts available yet.',
        style: AppTypography.custom(
          color: AppColors.textMuted,
          size: AppText.bodySize,
          weight: FontWeight.w400,
        ),
      ),
    );
  }
}
