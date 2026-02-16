import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/secondary_tag_model.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class SecondaryLabel extends StatelessWidget {
  const SecondaryLabel(this.title, {super.key, this.useDisplayText = true});

  final SecondaryTag title;
  final bool useDisplayText;

  @override
  Widget build(BuildContext context) {
    String displayText = title.toString();
    
    if (useDisplayText && displayText.length > 7) {
      displayText = '${displayText.substring(0, 7)}...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.darkGrey200,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: StyledBodyText(useDisplayText ? displayText : title.toString()),
    );
  }
}
