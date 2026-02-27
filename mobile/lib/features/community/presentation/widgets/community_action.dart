import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class CommunityAction extends StatelessWidget {
  const CommunityAction({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        if (value.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTypography.custom(
              color: color,
              size: 12,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}
