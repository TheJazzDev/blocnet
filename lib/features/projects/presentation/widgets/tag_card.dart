import 'package:blocknet/app/theme.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class TagCard extends StatelessWidget {
  TagCard({
    required this.label,
    required this.iconName,
    required this.onTap,
    super.key,
  });

  final String label;
  final String iconName;
  final void Function() onTap;

  final Map<String, IconData> iconMap = {
    'timeline': Symbols.timeline,
    'emergency': Symbols.e911_emergency,
    'brightness': Symbols.brightness_alert,
    'calm': Symbols.sentiment_calm,
  };

  @override
  Widget build(BuildContext context) {
    IconData? iconData = iconMap[iconName];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        height: 131,
        margin: EdgeInsets.only(right: 8),
        padding: EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 40),
        decoration: BoxDecoration(
          color: AppColors.darkGrey200,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.darkGrey300,
                borderRadius: const BorderRadius.all(Radius.circular(100)),
              ),
              child: Icon(
                iconData,
                size: 20,
                color: AppColors.darkGrey600,
              ),
            ),
            Expanded(child: SizedBox()),
            StyledTitleMedium(label),
          ],
        ),
      ),
    );
  }
}
