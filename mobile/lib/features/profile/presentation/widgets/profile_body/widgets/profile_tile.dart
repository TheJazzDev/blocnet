import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Navigation row used by every list section of the profile body.
/// Renders as a bordered card in card mode and as a divided row in list
/// mode, following the global [FeedViewModeStore].
class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
    this.iconColor,
    this.titleColor,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final Color? iconColor;
  final Color? titleColor;

  /// Optional widget shown before the chevron (e.g. a status pill).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isCardMode =
        context.watch<FeedViewModeStore>().mode == FeedViewMode.card;

    final tile = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppSurface(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: isCardMode ? 8 : 0),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg, vertical: AppSpace.md),
        child: Row(
          children: [
            if (isCardMode)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(AppRadius.mdValue),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Icon(
                  icon,
                  size: AppIcon.sm,
                  color: iconColor ?? AppColors.textMuted,
                ),
              )
            else
              Icon(icon,
                  size: AppIcon.md, color: iconColor ?? AppColors.textMuted),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: titleColor ?? AppColors.textPrimary,
                      size: AppText.labelSize,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: AppText.captionSize,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: AppSpace.sm),
            ],
            Icon(Icons.chevron_right,
                size: AppIcon.md, color: AppColors.textFaint),
          ],
        ),
      ),
    );

    if (isCardMode) return tile;

    return Column(
      children: [
        tile,
        if (showDivider)
          Divider(
            height: 1,
            color: AppColors.borderSubtle.withValues(alpha: 0.8),
          ),
      ],
    );
  }
}

/// Small rounded status pill used as a [ProfileTile.trailing].
class ProfileTilePill extends StatelessWidget {
  const ProfileTilePill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm, vertical: AppSpace.hair),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.fullValue),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTypography.custom(
          color: color,
          size: AppText.captionSize,
          weight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
