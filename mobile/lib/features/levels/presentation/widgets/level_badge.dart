import 'package:blocnet/app/config.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A reusable level badge widget that displays a user's level
/// Can be used in comments, posts, profiles, and anywhere a level needs to be shown
class LevelBadge extends StatelessWidget {
  const LevelBadge({
    super.key,
    required this.level,
    this.size = LevelBadgeSize.small,
    this.showName = false,
    this.showLevelNumber = true,
  });

  final UserLevelModel level;
  final LevelBadgeSize size;
  final bool showName;
  final bool showLevelNumber;

  @override
  Widget build(BuildContext context) {
    final iconSize = _getIconSize();
    final fontSize = _getFontSize();
    final badgeColor = _parseColor(level.color);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level icon container
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: badgeColor,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: _buildLevelIcon(),
          ),
        ),
        if (showLevelNumber || showName) ...[
          const SizedBox(width: 4),
          _buildLevelText(fontSize),
        ],
      ],
    );
  }

  Widget _buildLevelIcon() {
    if (level.iconUrl.isEmpty) {
      // Fallback to level number if no icon
      return _buildFallbackLevelText();
    }

    // Check if it's a full URL or relative path
    final iconUrl = level.iconUrl.startsWith('http')
        ? level.iconUrl
        : '${AppConfig.apiBaseUrl.replaceAll('/api', '')}${level.iconUrl}';
    final isSvg = iconUrl.toLowerCase().endsWith('.svg');
    final resolvedIconUrl = isSvg ? _withCacheBuster(iconUrl) : iconUrl;

    if (isSvg) {
      return SvgPicture.network(
        resolvedIconUrl,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _buildLoadingSpinner(),
        errorBuilder: (_, __, ___) => _buildFallbackLevelText(),
      );
    }

    return CachedNetworkImage(
      imageUrl: resolvedIconUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildLoadingSpinner(),
      errorWidget: (context, url, error) => _buildFallbackLevelText(),
    );
  }

  String _withCacheBuster(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final qp = Map<String, String>.from(uri.queryParameters)
      ..putIfAbsent('v', () => 'level-icons-v2');
    return uri.replace(queryParameters: qp).toString();
  }

  Widget _buildLoadingSpinner() {
    return Center(
      child: SizedBox(
        width: _getIconSize() * 0.5,
        height: _getIconSize() * 0.5,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildFallbackLevelText() {
    return Center(
      child: Text(
        '${level.level}',
        style: TextStyle(
          color: Colors.white,
          fontSize: _getIconSize() * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLevelText(double fontSize) {
    final parts = <String>[];
    if (showLevelNumber) {
      parts.add('Level ${level.level}');
    }
    if (showName) {
      parts.add(level.name);
    }

    return Text(
      parts.join(' • '),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  double _getIconSize() {
    switch (size) {
      case LevelBadgeSize.tiny:
        return 16.0;
      case LevelBadgeSize.small:
        return 20.0;
      case LevelBadgeSize.medium:
        return 32.0;
      case LevelBadgeSize.large:
        return 48.0;
      case LevelBadgeSize.extraLarge:
        return 64.0;
    }
  }

  double _getFontSize() {
    switch (size) {
      case LevelBadgeSize.tiny:
        return 10.0;
      case LevelBadgeSize.small:
        return 11.0;
      case LevelBadgeSize.medium:
        return 13.0;
      case LevelBadgeSize.large:
        return 15.0;
      case LevelBadgeSize.extraLarge:
        return 17.0;
    }
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return Colors.grey[600]!;
    }

    try {
      final hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {
      // Fallback to grey if parsing fails
    }

    return Colors.grey[600]!;
  }
}

/// Level badge size options
enum LevelBadgeSize {
  tiny, // 16px - for very compact spaces
  small, // 20px - for comments, inline text
  medium, // 32px - for cards, list items
  large, // 48px - for profile headers
  extraLarge, // 64px - for dedicated level displays
}

/// A compact level badge that only shows the icon with a tooltip
class LevelBadgeIcon extends StatelessWidget {
  const LevelBadgeIcon({
    super.key,
    required this.level,
    this.size = LevelBadgeSize.small,
  });

  final UserLevelModel level;
  final LevelBadgeSize size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Level ${level.level} • ${level.name}',
      child: LevelBadge(
        level: level,
        size: size,
        showName: false,
        showLevelNumber: false,
      ),
    );
  }
}

/// A full level badge with level number and name
class LevelBadgeFull extends StatelessWidget {
  const LevelBadgeFull({
    super.key,
    required this.level,
    this.size = LevelBadgeSize.medium,
  });

  final UserLevelModel level;
  final LevelBadgeSize size;

  @override
  Widget build(BuildContext context) {
    return LevelBadge(
      level: level,
      size: size,
      showName: true,
      showLevelNumber: true,
    );
  }
}
