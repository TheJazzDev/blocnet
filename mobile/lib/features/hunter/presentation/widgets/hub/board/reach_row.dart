import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// Tips and followers, deliberately demoted: flat tiles, no accent, 15px
/// figures against coverage's 32. A receipt for the work, not its headline.
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _Tile(
              icon: Icons.volunteer_activism_outlined,
              value: tips,
              label: 'Tips',
            ),
          ),
          const SizedBox(width: 8),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.hubCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hubTileEdge),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.zincCaption),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HubType.body(AppColors.zincBody,
                          weight: FontWeight.w700, height: 1.3)
                      .copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  label.toUpperCase(),
                  style: HubType.caps(AppColors.zincCaption),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
