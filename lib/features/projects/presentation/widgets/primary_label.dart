import 'package:blocknet/app/app_theme.dart';
import 'package:blocknet/shared/styles/text.dart';
import 'package:flutter/material.dart';

class PrimaryLabel extends StatelessWidget {
  const PrimaryLabel(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
          color: AppColors.darkGrey200,
          borderRadius: BorderRadius.all(Radius.circular(20))),
      child: StyledBodyText(title),
    );
  }
}
 