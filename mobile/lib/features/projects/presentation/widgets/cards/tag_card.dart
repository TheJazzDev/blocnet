import 'package:blocnet/app/theme.dart';
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
  final VoidCallback onTap;

  final Map<String, IconData> _iconMap = {
    'timeline': Symbols.timeline,
    'emergency': Symbols.e911_emergency,
    'brightness': Symbols.brightness_alert,
    'calm': Symbols.sentiment_calm,
    'post': Symbols.post,
    'style': Symbols.style,
  };

  // Map icon names to accent colors for identity
  static const Map<String, int> _accentMap = {
    'timeline': 0xFF00E5B8, // teal — Trending
    'emergency': 0xFF00E5B8, // teal — High
    'brightness': 0xFF339DFF, // blue — Medium
    'calm': 0xFF737373, // muted — Low
  };

  @override
  Widget build(BuildContext context) {
    final iconData = _iconMap[iconName] ?? Symbols.style;
    final accentColor = Color(_accentMap[iconName] ?? 0xFF525252);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 110,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon with tinted container
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, size: 17, color: accentColor),
            ),
            // Label
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
