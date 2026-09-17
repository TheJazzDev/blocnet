import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/progress_style.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

export 'package:blocnet/features/badges/presentation/widgets/badge_chips.dart';

/// A compact badge icon shown next to usernames and in the badge gallery.
///
/// Flat: a faint tint of the badge's rarity colour behind the artwork and a
/// hairline in the same colour. No gradient, no glow.
class BadgeIcon extends StatelessWidget {
  const BadgeIcon({
    super.key,
    required this.badge,
    this.size = BadgeSize.small,
    this.onTap,
    this.showTooltip = true,
  });

  final BadgeModel badge;
  final BadgeSize size;
  final VoidCallback? onTap;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    final dimensions = size.dimensions;
    final tone = badge.rarity.tone;

    Widget fallbackIcon() {
      return ColoredBox(
        color: tone.withValues(alpha: 0.14),
        child: Icon(
          Icons.emoji_events_rounded,
          size: dimensions * 0.6,
          color: tone,
        ),
      );
    }

    final badgeWidget = GestureDetector(
      onTap: onTap,
      child: Container(
        width: dimensions,
        height: dimensions,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: tone.withValues(alpha: 0.35)),
        ),
        child: ClipOval(
          child: isUsableBadgeImageUrl(badge.imageUrl)
              ? CachedNetworkImage(
                  imageUrl: badge.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      ColoredBox(color: tone.withValues(alpha: 0.12)),
                  errorWidget: (context, url, error) => fallbackIcon(),
                )
              : fallbackIcon(),
        ),
      ),
    );

    if (!showTooltip) return badgeWidget;

    return Tooltip(
      message: '${badge.name}\n${badge.description}',
      preferBelow: false,
      textStyle: AppText.label(AppColors.textPrimary),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.borderMuted),
      ),
      child: badgeWidget,
    );
  }
}

/// True for an http(s) URL that is not a known placeholder host.
bool isUsableBadgeImageUrl(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return false;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return false;

  const blockedHosts = {
    'via.placeholder.com',
    'placeholder.com',
    'placehold.co',
    'placehold.it',
  };
  return !blockedHosts.contains(uri.host.toLowerCase());
}

enum BadgeSize {
  tiny(12),
  small(16),
  medium(24),
  large(40),
  xlarge(60);

  const BadgeSize(this.dimensions);
  final double dimensions;
}

/// Widget to display user's primary badge next to their name
class UserBadge extends StatelessWidget {
  const UserBadge({
    super.key,
    this.badge,
    this.size = BadgeSize.small,
    this.onTap,
  });

  final BadgeModel? badge;
  final BadgeSize size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (badge == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: AppSpace.xs),
      child: BadgeIcon(
        badge: badge!,
        size: size,
        onTap: onTap,
        showTooltip: true,
      ),
    );
  }
}

/// Widget to display multiple badges in a horizontal list
class BadgeList extends StatelessWidget {
  const BadgeList({
    super.key,
    required this.badges,
    this.size = BadgeSize.medium,
    this.maxDisplay = 5,
    this.spacing = 4.0,
    this.onBadgeTap,
    this.onMoreTap,
  });

  final List<BadgeModel> badges;
  final BadgeSize size;
  final int maxDisplay;
  final double spacing;
  final void Function(BadgeModel badge)? onBadgeTap;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    final displayBadges = badges.take(maxDisplay).toList();
    final remaining = badges.length - displayBadges.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final badge in displayBadges)
          Padding(
            padding: EdgeInsets.only(right: spacing),
            child: BadgeIcon(
              badge: badge,
              size: size,
              onTap: onBadgeTap != null ? () => onBadgeTap!(badge) : null,
            ),
          ),
        if (remaining > 0)
          GestureDetector(
            onTap: onMoreTap,
            child: Container(
              width: size.dimensions,
              height: size.dimensions,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgElevated,
                border: Border.all(color: AppColors.borderMuted),
              ),
              child: Center(
                child: Text(
                  '+$remaining',
                  style: TextStyle(
                    fontSize: size.dimensions * 0.4,
                    fontWeight: AppText.bold,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
