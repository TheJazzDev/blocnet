import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_meta.dart';
import 'package:blocnet/shared/widgets/app_button.dart';
import 'package:blocnet/shared/widgets/app_surface.dart';
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
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
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
            AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMuted,
                  borderRadius: AppRadius.full,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(_title, style: AppText.title(AppColors.textPrimary)),
            const SizedBox(height: AppSpace.xs),
            Text(
              'Each space has its own bottom bar. Your profile, badges and '
              'levels are the same everywhere. Switch from the chip at the '
              'top right.',
              style: AppText.label(AppColors.textMuted, weight: AppText.regular)
                  .copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpace.lg),
            AppSurface.flush(
              child: Column(
                children: [
                  for (final space in spaces) ...[
                    _SpaceRow(space: space),
                    if (space != spaces.last)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderSubtle,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            AppButton(
              label: 'Got it',
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
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
    return Padding(
      padding: AppSpace.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: space.accent.withValues(alpha: 0.12),
              borderRadius: AppRadius.md,
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
                  style: AppText.body(
                    AppColors.textPrimary,
                    weight: AppText.bold,
                  ),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  space.purpose,
                  style: AppText.label(
                    AppColors.textMuted,
                    weight: AppText.regular,
                  ).copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
