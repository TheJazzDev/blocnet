import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// `layers YOUR GEMS ··· 5 CURRENT` — the old app's small grey section
/// label (`TOP HUNTERS`, `COMMUNITY VOICE`).
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
      padding: const EdgeInsets.fromLTRB(
        HubInsets.gutter,
        AppSpace.xl,
        HubInsets.gutter,
        AppSpace.md,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIcon.sm, color: AppColors.textFaint),
            AppSpace.wGapSm,
          ],
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HubType.caps(AppColors.textFaint, weight: AppText.semibold),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!.toUpperCase(),
              style: HubType.caps(AppColors.textFaint, weight: AppText.semibold),
            ),
        ],
      ),
    );
  }
}
