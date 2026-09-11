import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Following / Tips Sent / Badges counters under the hero. Everyone.
class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({
    super.key,
    required this.followingCount,
    required this.tipsSent,
    required this.badgeCount,
    required this.accent,
  });

  final int followingCount;
  final String tipsSent;
  final int badgeCount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Stat(value: '$followingCount', label: 'Following', accent: accent),
          const _Separator(),
          _Stat(value: tipsSent, label: 'Tips Sent', accent: accent),
          const _Separator(),
          _Stat(value: '$badgeCount', label: 'Badges', accent: accent),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
      child: Container(
        width: 1,
        height: 28,
        color: AppColors.borderSubtle.withValues(alpha: 0.85),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.hair),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: accent,
                size: AppText.bodySize,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpace.hair),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: AppText.captionSize,
                weight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
