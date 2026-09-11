import 'package:blocnet/app/theme.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _title,
              style: AppTypography.custom(
                size: 18,
                weight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'A space changes which tools sit in your bottom bar. Your '
              'profile, badges, quests and levels stay the same in every '
              'space. Switch any time from the chip in the top-right corner.',
              style: AppTypography.custom(
                size: 12,
                weight: FontWeight.w400,
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            for (final space in spaces) ...[
              _SpaceRow(space: space),
              if (space != spaces.last) const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: AppTypography.custom(
                    size: 13,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(14),
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(space.icon, size: 19, color: space.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${space.label} space',
                  style: AppTypography.custom(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  space.purpose,
                  style: AppTypography.custom(
                    size: 11,
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
