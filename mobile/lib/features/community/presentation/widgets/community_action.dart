import 'package:blocnet/app/tokens/tokens.dart';
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm, horizontal: AppSpace.hair),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIcon.md, color: color),
            if (value.isNotEmpty) ...[
              const SizedBox(width: AppSpace.sm),
              Text(
                value,
                style: AppTypography.custom(
                  color: color,
                  size: AppText.labelSize,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
