import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// `layers YOUR GEMS ··· 5 CURRENT`.
class HubSectionHeader extends StatelessWidget {
  const HubSectionHeader({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
  });

  final String label;
  final IconData? icon;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.zincQuiet),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HubType.caps(AppColors.zincCaption, tracking: 1.54),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!.toUpperCase(),
              style: HubType.caps(AppColors.zincQuiet),
            ),
        ],
      ),
    );
  }
}
