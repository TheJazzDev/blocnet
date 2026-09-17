import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// Tips and followers, deliberately demoted: two small flat tiles like the
/// old mining stats, neutral icons, no accent. A receipt for the work, not
/// its headline.
class ReachRow extends StatelessWidget {
  const ReachRow({
    super.key,
    required this.tips,
    required this.followers,
  });

  /// `18,240 BNP`, or `0` when nothing has been tipped.
  final String tips;
  final String followers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HubInsets.gutter,
        AppSpace.md,
        HubInsets.gutter,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tile(
              icon: Icons.volunteer_activism_outlined,
              value: tips,
              label: 'Tips',
            ),
          ),
          AppSpace.wGapMd,
          Expanded(
            child: _Tile(
              icon: Icons.groups_outlined,
              value: followers,
              label: 'Followers',
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpace.allMd,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: AppRadius.sm,
            ),
            child: Icon(icon, size: AppIcon.sm, color: AppColors.textMuted),
          ),
          AppSpace.wGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: HubType.caps(AppColors.textFaint,
                      weight: AppText.semibold),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(AppColors.textPrimary,
                          weight: AppText.bold)
                      .merge(AppText.tabular),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
