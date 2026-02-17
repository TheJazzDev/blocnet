import 'package:blocnet/app/theme.dart';
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
    final IconData? iconData = iconMap[iconName];

    return Container(
      height: 131,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
            child: Icon(iconData, size: 18, color: AppColors.textMuted),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 10,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$value',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
