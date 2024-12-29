import 'package:blocknet/app/theme.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class StatCard extends StatelessWidget {
  StatCard({
    required this.label,
    required this.value,
    required this.iconName,
    super.key,
  });

  final String label;
  final int value;
  final String iconName;

  final Map<String, IconData> iconMap = {
    'post': Symbols.post,
    'style': Icons.style,
    'emergency': Symbols.e911_emergency,
  };

  @override
  Widget build(BuildContext context) {
    IconData? iconData = iconMap[iconName];

    return Container(
      height: 131,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkGrey200,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 80, child: StyledBodyText500(label, size: 10)),
              SizedBox(height: 4),
              StyledBodyText700('$value', size: 14),
            ],
          )
        ],
      ),
    );
  }
}
