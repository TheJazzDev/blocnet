import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A remote image that caches to disk and decodes at display size.
///
/// `Image.network` does neither: it re-downloads on every cold start, and it
/// decodes at the source resolution, so a large upload becomes a multi-megabyte
/// bitmap on the UI isolate to fill a small logo box. That decode is what makes
/// a list stutter while scrolling.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String url;

  /// Shown while loading, when [url] is empty, and when the fetch fails.
  final Widget fallback;

  final double? width;
  final double? height;
  final BoxFit fit;

  /// Ceiling on the decoded bitmap, in real pixels, so an unbounded axis can
  /// never ask for a full-resolution decode.
  static const int _maxDecodePixels = 2048;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return SizedBox(width: width, height: height, child: fallback);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);

        int? decodeExtent(double? explicit, double maxConstraint) {
          final extent =
              explicit ?? (maxConstraint.isFinite ? maxConstraint : null);
          if (extent == null) return _maxDecodePixels;
          if (extent <= 0) return null;
          return (extent * dpr).round().clamp(1, _maxDecodePixels);
        }

        return CachedNetworkImage(
          imageUrl: url.trim(),
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: decodeExtent(width, constraints.maxWidth),
          memCacheHeight: decodeExtent(height, constraints.maxHeight),
          placeholder: (_, __) => fallback,
          errorWidget: (_, __, ___) => fallback,
        );
      },
    );
  }
}
