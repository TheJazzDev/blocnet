import 'package:blocnet/app/config.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Draws the artwork for a level at a given pixel [size].
///
/// Resolution order:
/// 1. Bundled SVG badge matched by level number, then slug.
/// 2. Remote `level.iconUrl` (SVG or raster) served by the backend.
/// 3. A coloured circle showing the level number.
///
/// Badge artwork is drawn as-is, with no circular mask, so non-round shapes
/// such as shields, hexagons and seals keep their silhouette.
class LevelBadgeArtwork extends StatelessWidget {
  const LevelBadgeArtwork({
    super.key,
    required this.level,
    required this.size,
  });

  final UserLevelModel level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = LevelBadgeAssets.pathFor(
      level: level.level,
      slug: level.slug,
    );
    if (asset != null) {
      return SvgPicture.asset(
        asset,
        width: size,
        height: size,
        semanticsLabel: 'Level ${level.level} ${level.name}',
      );
    }

    if (level.iconUrl.isNotEmpty) {
      return _RemoteLevelIcon(level: level, size: size);
    }

    return LevelNumberFallback(level: level, size: size);
  }
}

class _RemoteLevelIcon extends StatelessWidget {
  const _RemoteLevelIcon({required this.level, required this.size});

  final UserLevelModel level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = _resolveUrl(level.iconUrl);
    final isSvg = url.toLowerCase().split('?').first.endsWith('.svg');

    if (isSvg) {
      return SvgPicture.network(
        url,
        width: size,
        height: size,
        placeholderBuilder: (_) => _LoadingSpinner(size: size),
        errorBuilder: (_, __, ___) =>
            LevelNumberFallback(level: level, size: size),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholder: (_, __) => _LoadingSpinner(size: size),
      errorWidget: (_, __, ___) =>
          LevelNumberFallback(level: level, size: size),
    );
  }

  static String _resolveUrl(String iconUrl) {
    if (iconUrl.startsWith('http')) return iconUrl;
    return '${AppConfig.apiBaseUrl.replaceAll('/api', '')}$iconUrl';
  }
}

class _LoadingSpinner extends StatelessWidget {
  const _LoadingSpinner({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SizedBox(
          width: size * 0.5,
          height: size * 0.5,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Coloured circle with the level number, used when no artwork is available.
class LevelNumberFallback extends StatelessWidget {
  const LevelNumberFallback({
    super.key,
    required this.level,
    required this.size,
  });

  final UserLevelModel level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: parseLevelColor(level.color),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '${level.level}',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Parses a `#RRGGBB` or `#AARRGGBB` hex string, falling back to grey.
Color parseLevelColor(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) return Colors.grey.shade600;
  try {
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    if (hex.length == 8) return Color(int.parse(hex, radix: 16));
  } catch (_) {
    // fall through
  }
  return Colors.grey.shade600;
}
