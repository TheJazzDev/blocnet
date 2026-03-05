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
    'emergency': 0xFFEF4444, // red — High urgency
    'brightness': 0xFFF97316, // orange — Medium urgency
    'calm': 0xFF10B981, // green — Low urgency
  };

  @override
  Widget build(BuildContext context) {
    final iconData = _iconMap[iconName] ?? Symbols.style;
    final accentColor = Color(_accentMap[iconName] ?? 0xFF525252);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 105,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.15),
              accentColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon with tinted container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(alpha: 0.25),
                    accentColor.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Icon(iconData, size: 22, color: accentColor),
            ),
            // Label
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
