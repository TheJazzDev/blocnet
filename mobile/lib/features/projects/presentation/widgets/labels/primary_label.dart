import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:flutter/material.dart';

class PrimaryLabel extends StatelessWidget {
  const PrimaryLabel({required this.primaryTag, super.key});

  final PrimaryTag primaryTag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs, horizontal: AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.xlValue),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Text(
        primaryTag.toString(),
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppText.captionSize,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
