/// Bundled level badge artwork.
///
/// The badge SVGs live in `assets/badges/` and are the primary source for
/// level icons. Lookup is by level number first, because the number is unique
/// and immutable on the backend, and by slug second, because slugs have drifted
/// between environments (`blocnet-member` in one database, `pathfinder` in
/// the seed). A remote `iconUrl` is only used when neither matches, so a new
/// level added on the server still renders without an app release.
class LevelBadgeAssets {
  const LevelBadgeAssets._();

  static const String _dir = 'assets/badges';

  /// Level number to bundled badge file name (without extension).
  static const Map<int, String> byLevel = {
    1: 'newcomer',
    2: 'explorer',
    3: 'pathfinder',
    4: 'contributor',
    5: 'builder',
    6: 'advocate',
    7: 'veteran',
    8: 'champion',
    9: 'elite',
    10: 'expert',
    11: 'guardian',
    12: 'master',
    13: 'legend',
    14: 'titan',
    15: 'pioneer',
  };

  static final Set<String> _bundledNames = byLevel.values.toSet();

  /// Asset path for a level, or `null` when no bundled badge exists.
  ///
  /// [level] is the level number; [slug] is the backend slug and is only
  /// consulted when the number is unknown.
  static String? pathFor({required int level, String slug = ''}) {
    final byNumber = byLevel[level];
    if (byNumber != null) return '$_dir/$byNumber.svg';

    final name = _normalizeSlug(slug);
    if (name != null && _bundledNames.contains(name)) {
      return '$_dir/$name.svg';
    }
    return null;
  }

  static String? _normalizeSlug(String slug) {
    var s = slug.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s.startsWith('blocnet-')) s = s.substring('blocnet-'.length);
    return s;
  }
}
