import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/secondary_tag_model.dart';
import 'package:flutter/material.dart';

class SecondaryLabel extends StatelessWidget {
  const SecondaryLabel(this.tag, {super.key, this.useDisplayText = true});

  final SecondaryTag tag;
  final bool useDisplayText;

  @override
  Widget build(BuildContext context) {
    final raw = tag.toString();
    final displayText = (useDisplayText && raw.length > 8)
        ? '${raw.substring(0, 8)}…'
        : raw;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        useDisplayText ? displayText : raw,
        style: TextStyle(
          color: AppColors.primary300,
          fontSize: 11,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
