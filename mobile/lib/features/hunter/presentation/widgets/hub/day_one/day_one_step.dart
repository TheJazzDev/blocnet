import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// One numbered route on the day-one card. Without [onTap] it is a plain
/// statement: muted, no chevron, nothing to press.
class DayOneStep extends StatelessWidget {
  const DayOneStep({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final int number;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final live = onTap != null;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.hubStep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.chainIce.withValues(alpha: 0.12),
            ),
            child: Text(
              '$number',
              style: HubType.caps(AppColors.chainIce,
                  weight: FontWeight.w800, tracking: 0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HubType.rowTitle(
                    live ? AppColors.textPrimary : AppColors.zincMuted,
                  ),
                ),
                Text(
                  subtitle,
                  style: HubType.meta(
                    live ? AppColors.zincFaint : AppColors.zincDim,
                  ),
                ),
              ],
            ),
          ),
          if (live)
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.zincQuiet,
            ),
        ],
      ),
    );
    if (!live) return row;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }
}
