import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class PrimaryLabel extends StatelessWidget {
  const PrimaryLabel({required this.primaryTag, super.key});

  final PrimaryTag primaryTag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.darkGrey50,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: StyledBodyText(primaryTag.toString()),
    );
  }
}
