import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/badges/presentation/widgets/progress_style.dart';
import 'package:blocnet/services/engagement/badges_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Opens the badge details sheet.
Future<void> showBadgeDetailsSheet(
  BuildContext context, {
  required BadgeModel badge,
  required bool isEarned,
}) {
  return AppSheet.show<void>(
    context: context,
    title: 'Badge',
    icon: Icons.emoji_events_outlined,
    builder: (_) => BadgeDetailsSheet(badge: badge, isEarned: isEarned),
  );
}

/// A badge's artwork, name, pills and description, with the one action a
/// badge has: make it the primary badge shown next to your name.
class BadgeDetailsSheet extends StatelessWidget {
  const BadgeDetailsSheet({
    super.key,
    required this.badge,
    required this.isEarned,
  });

  final BadgeModel badge;
  final bool isEarned;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BadgesStore>();
    final isPrimary = store.primaryBadge?.id == badge.id;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Opacity(
                opacity: isEarned ? 1 : 0.4,
                child: BadgeIcon(
                  badge: badge,
                  size: BadgeSize.xlarge,
                  showTooltip: false,
                ),
              ),
              AppSpace.wGapLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.subtitle(
                        AppColors.textPrimary,
                        weight: AppText.bold,
                      ),
                    ),
                    AppSpace.gapSm,
                    Wrap(
                      spacing: AppSpace.xs,
                      runSpacing: AppSpace.xs,
                      children: [
                        BadgeRarityChip(rarity: badge.rarity, compact: true),
                        BadgeCategoryChip(
                          category: badge.category,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (badge.description.isNotEmpty) ...[
            AppSpace.gapLg,
            Text(
              badge.description,
              style: AppText.body(AppColors.textSecondary),
            ),
          ],
          AppSpace.gapXl,
          if (!isEarned)
            _LockedLine(points: badge.pointsRequirement)
          else if (isPrimary)
            const AppButton(
              label: 'Primary badge',
              icon: Icons.check_rounded,
              onPressed: null,
              variant: AppButtonVariant.secondary,
              fullWidth: true,
            )
          else
            AppButton(
              label: 'Set as primary',
              icon: Icons.star_rounded,
              isLoading: store.isSettingPrimary,
              fullWidth: true,
              onPressed: () => _setPrimary(context, store),
            ),
        ],
      ),
    );
  }

  Future<void> _setPrimary(BuildContext context, BadgesStore store) async {
    final success = await store.setPrimaryBadge(badge.id);
    if (!context.mounted) return;
    if (success) {
      Navigator.pop(context);
      AppSnackbar.showSuccess(context, '${badge.name} is your primary badge');
    } else {
      AppSnackbar.showError(
        context,
        progressErrorText(
          store.lastError,
          fallback: 'Could not set primary badge. Try again.',
        ),
      );
    }
  }
}

class _LockedLine extends StatelessWidget {
  const _LockedLine({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      tone: AppSurfaceTone.elevated,
      width: double.infinity,
      padding: AppSpace.allMd,
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: AppIcon.sm,
            color: AppColors.textFaint,
          ),
          AppSpace.wGapSm,
          Expanded(
            child: Text(
              points > 0 ? 'Locked · unlocks at $points pts' : 'Locked',
              style: AppText.label(AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
