import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A compact badge icon widget that displays next to usernames
/// Similar to Discord's badge system
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
    final hasValidImage = _isUsableImageUrl(badge.imageUrl);
    final rarityColor = Color(badge.rarity.color);

    Widget fallbackIcon() {
      return Container(
        color: Colors.grey.shade800,
        child: Icon(
          Icons.emoji_events,
          size: dimensions * 0.6,
          color: rarityColor,
        ),
      );
    }

    Widget badgeWidget = GestureDetector(
      onTap: onTap,
      child: Container(
        width: dimensions,
        height: dimensions,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: rarityColor.withValues(alpha: 0.3),
            width: size == BadgeSize.large ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withValues(alpha: 0.2),
              blurRadius: size == BadgeSize.large ? 8 : 4,
              spreadRadius: size == BadgeSize.large ? 2 : 1,
            ),
          ],
        ),
        child: ClipOval(
          child: hasValidImage
              ? CachedNetworkImage(
                  imageUrl: badge.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade800,
                    child: Center(
                      child: SizedBox(
                        width: dimensions * 0.5,
                        height: dimensions * 0.5,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            rarityColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => fallbackIcon(),
                )
              : fallbackIcon(),
        ),
      ),
    );

    if (showTooltip) {
      return Tooltip(
        message: '${badge.name}\n${badge.description}',
        preferBelow: false,
        textStyle: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: rarityColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: badgeWidget,
      );
    }

    return badgeWidget;
  }

  bool _isUsableImageUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    if (!uri.hasScheme || !uri.hasAuthority) return false;
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }
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
      padding: const EdgeInsets.only(left: 4),
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
        ...displayBadges.map((badge) => Padding(
              padding: EdgeInsets.only(right: spacing),
              child: BadgeIcon(
                badge: badge,
                size: size,
                onTap: onBadgeTap != null ? () => onBadgeTap!(badge) : null,
              ),
            )),
        if (remaining > 0)
          GestureDetector(
            onTap: onMoreTap,
            child: Container(
              width: size.dimensions,
              height: size.dimensions,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade800,
                border: Border.all(
                  color: Colors.grey.shade600,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '+$remaining',
                  style: TextStyle(
                    fontSize: size.dimensions * 0.4,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Badge rarity indicator chip
class BadgeRarityChip extends StatelessWidget {
  const BadgeRarityChip({
    super.key,
    required this.rarity,
    this.compact = false,
  });

  final BadgeRarity rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(rarity.color).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(rarity.color).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars,
            size: compact ? 12 : 14,
            color: Color(rarity.color),
          ),
          const SizedBox(width: 4),
          Text(
            rarity.displayName,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: Color(rarity.color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge category chip
class BadgeCategoryChip extends StatelessWidget {
  const BadgeCategoryChip({
    super.key,
    required this.category,
    this.compact = false,
  });

  final BadgeCategory category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade600,
          width: 1,
        ),
      ),
      child: Text(
        category.displayName,
        style: TextStyle(
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
      ),
    );
  }
}
