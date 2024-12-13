import 'package:blocknet/app/app_theme.dart';
import 'package:blocknet/features/projects/data/models/secondary_tag.dart';
import 'package:blocknet/shared/styles/text.dart';
import 'package:flutter/material.dart';

class SecondaryLabel extends StatelessWidget {
  const SecondaryLabel(this.title, {super.key});

  final SecondaryTag title;

  @override
  Widget build(BuildContext context) {
    String displayText = title.toString();
    if (displayText.length > 7) {
      displayText = '${displayText.substring(0, 7)}...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.darkGrey200,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: StyledBodyText(displayText),
    );
  }
}
