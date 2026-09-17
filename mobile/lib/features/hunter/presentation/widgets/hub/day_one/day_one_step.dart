import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// One numbered route on the day-one card, drawn as the old profile's list
/// tile. Without [onTap] it is a plain statement: muted, no chevron,
/// nothing to press.
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md + 2,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: AppRadius.md,
      ),
      child: Row(
        children: [
          _Number(number: number, live: live),
          AppSpace.wGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body(
                    live ? AppColors.textPrimary : AppColors.textMuted,
                    weight: AppText.semibold,
                  ),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  subtitle,
                  style: AppText.label(
                    live ? AppColors.textMuted : AppColors.textFaint,
                    weight: AppText.regular,
                  ),
                ),
              ],
            ),
          ),
          if (live)
            Icon(
              Icons.chevron_right_rounded,
              size: AppIcon.md,
              color: AppColors.textFaint,
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

class _Number extends StatelessWidget {
  const _Number({required this.number, required this.live});

  final int number;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final color = live ? HubTone.accent : AppColors.textFaint;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bgSurface,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$number',
        style: AppText.label(color, weight: AppText.bold),
      ),
    );
  }
}
