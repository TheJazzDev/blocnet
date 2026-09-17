import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_parts.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// `ICON SECTION LABEL` above a hub block.
class ModHubHeader extends StatelessWidget {
  const ModHubHeader({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      title: label,
      icon: icon,
      padding: const EdgeInsets.only(
        top: AppSpace.xl,
        bottom: AppSpace.md,
      ),
    );
  }
}

/// Active restrictions: a single stat row. It has no queue on mobile, so it
/// gets no chevron.
class ModHubRestrictionsCard extends StatelessWidget {
  const ModHubRestrictionsCard({super.key, required this.count});

  /// Null while loading or after a failed load.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final value = count;
    return AppSurface(
      padding: AppSpace.row,
      child: Row(
        children: [
          AppIconSquare(
            icon: Icons.block_rounded,
            color: AppColors.tagPartnership,
            size: 36,
            iconSize: AppIcon.md,
          ),
          AppSpace.wGapMd,
          Expanded(
            child: Text(
              'Active restrictions',
              style: ModText.rowTitle(AppColors.textPrimary),
            ),
          ),
          Text(
            value == null ? '—' : '$value',
            style: AppText.subtitle(
              AppColors.textPrimary,
              weight: AppText.bold,
            ).merge(AppText.tabular),
          ),
        ],
      ),
    );
  }
}

/// The house rules, short.
class ModHubGuidelinesCard extends StatelessWidget {
  const ModHubGuidelinesCard({super.key});

  static const _rules = [
    'Review reports the same day.',
    'Apply the same standard to everyone.',
    'Write down why you decided.',
    'Admins review appeals.',
  ];

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _rules.length; i++) ...[
            if (i > 0) AppSpace.gapSm,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.check_rounded,
                    size: AppIcon.sm,
                    color: AppColors.textFaint,
                  ),
                ),
                AppSpace.wGapSm,
                Expanded(
                  child: Text(
                    _rules[i],
                    style: ModText.body(AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
