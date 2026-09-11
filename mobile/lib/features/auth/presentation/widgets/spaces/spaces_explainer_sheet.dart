import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_meta.dart';
import 'package:flutter/material.dart';

/// One-time explainer shown the first time a user with more than one
/// space opens the app. Names each available space and what it is for.
class SpacesExplainerSheet extends StatelessWidget {
  const SpacesExplainerSheet({super.key, required this.spaces});

  final List<SpaceMeta> spaces;

  /// SharedPreferences key that records the explainer was shown to [userId].
  static String seenKeyFor(String userId) =>
      'blocnet_spaces_explainer_seen_$userId';

  static Future<void> show(
    BuildContext context, {
    required List<SpaceMeta> spaces,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SpacesExplainerSheet(spaces: spaces),
    );
  }

  String get _title {
    final count = spaces.length;
    final word = switch (count) {
      2 => 'two',
      3 => 'three',
      _ => '$count',
    };
    return 'You have $word spaces';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMuted,
                  borderRadius: BorderRadius.circular(AppRadius.fullValue),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              _title,
              style: AppTypography.custom(
                size: AppText.titleSize,
                weight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              'A space changes which tools sit in your bottom bar. Your '
              'profile, badges, quests and levels stay the same in every '
              'space. Switch any time from the chip in the top-right corner.',
              style: AppTypography.custom(
                size: AppText.bodySize,
                weight: FontWeight.w400,
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            for (final space in spaces) ...[
              _SpaceRow(space: space),
              if (space != spaces.last) const SizedBox(height: AppSpace.sm),
            ],
            const SizedBox(height: AppSpace.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.mdValue),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: AppTypography.custom(
                    size: AppText.labelSize,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceRow extends StatelessWidget {
  const _SpaceRow({required this.space});

  final SpaceMeta space;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(color: space.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: space.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.mdValue),
            ),
            child: Icon(space.icon, size: AppIcon.md, color: space.accent),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${space.label} space',
                  style: AppTypography.custom(
                    size: AppText.labelSize,
                    weight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  space.purpose,
                  style: AppTypography.custom(
                    size: AppText.captionSize,
                    weight: FontWeight.w400,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
