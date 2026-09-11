import 'dart:ui';

import 'package:blocnet/features/levels/data/models/user_level_model.dart';

/// One of the five progression tiers, each spanning three levels.
///
/// The palette mirrors the backend seed (`seed.levels.ts`) and is used as a
/// fallback when a level arrives without a `color`. Use [colorFor] to resolve
/// the accent for a concrete level, which prefers the server-provided value.
class LevelTier {
  const LevelTier._({
    required this.index,
    required this.name,
    required this.shape,
    required this.minLevel,
    required this.maxLevel,
    required this.fallbackColor,
  });

  /// Zero-based tier position (Iron = 0 … Ruby = 4).
  final int index;
  final String name;

  /// Badge silhouette used by the bundled artwork for this tier.
  final String shape;
  final int minLevel;
  final int maxLevel;
  final Color fallbackColor;

  static const int levelsPerTier = 3;

  static const LevelTier iron = LevelTier._(
    index: 0,
    name: 'Iron',
    shape: 'Circle',
    minLevel: 1,
    maxLevel: 3,
    fallbackColor: Color(0xFF8A96A8),
  );

  static const LevelTier jade = LevelTier._(
    index: 1,
    name: 'Jade',
    shape: 'Hexagon',
    minLevel: 4,
    maxLevel: 6,
    fallbackColor: Color(0xFF2AA876),
  );

  static const LevelTier amethyst = LevelTier._(
    index: 2,
    name: 'Amethyst',
    shape: 'Shield',
    minLevel: 7,
    maxLevel: 9,
    fallbackColor: Color(0xFF8B5CF6),
  );

  static const LevelTier gold = LevelTier._(
    index: 3,
    name: 'Gold',
    shape: 'Octagon',
    minLevel: 10,
    maxLevel: 12,
    fallbackColor: Color(0xFFF0B429),
  );

  static const LevelTier ruby = LevelTier._(
    index: 4,
    name: 'Ruby',
    shape: 'Seal',
    minLevel: 13,
    maxLevel: 15,
    fallbackColor: Color(0xFFE23D4A),
  );

  /// All tiers in progression order.
  static const List<LevelTier> all = [iron, jade, amethyst, gold, ruby];

  /// Resolves the tier for a level number. Levels below 1 map to Iron and
  /// levels above 15 map to Ruby so an unexpected server value never throws.
  static LevelTier forLevel(int level) {
    final raw = (level - 1) ~/ levelsPerTier;
    final clamped = raw.clamp(0, all.length - 1);
    return all[clamped];
  }

  /// Human readable range, e.g. `Levels 4–6`.
  String get rangeLabel => 'Levels $minLevel–$maxLevel';

  bool contains(int level) => level >= minLevel && level <= maxLevel;

  bool get isFirst => index == 0;
  bool get isLast => index == all.length - 1;

  /// Accent colour for [level]: the server colour when it parses, otherwise
  /// the tier palette.
  Color colorFor(UserLevelModel? level) {
    return tryParseHexColor(level?.color) ?? fallbackColor;
  }
}

/// Convenience accessors on a level.
extension UserLevelTier on UserLevelModel {
  LevelTier get tier => LevelTier.forLevel(level);

  /// Tier accent for this level, preferring the server-provided colour.
  Color get tierColor => tier.colorFor(this);
}

/// A tier together with the levels that belong to it, in level order.
class LevelTierSection {
  const LevelTierSection({
    required this.tier,
    required this.levels,
    required this.color,
  });

  final LevelTier tier;
  final List<UserLevelModel> levels;

  /// Accent for the whole section, taken from the first level that carries a
  /// valid colour, otherwise the tier palette.
  final Color color;

  bool get isEmpty => levels.isEmpty;
}

/// Groups [levels] into ordered tier sections. Tiers without any level are
/// omitted so a partial server response never renders empty headers.
List<LevelTierSection> groupLevelsByTier(List<UserLevelModel> levels) {
  final buckets = <int, List<UserLevelModel>>{};
  for (final level in levels) {
    buckets
        .putIfAbsent(LevelTier.forLevel(level.level).index, () => [])
        .add(level);
  }

  final sections = <LevelTierSection>[];
  for (final tier in LevelTier.all) {
    final bucket = buckets[tier.index];
    if (bucket == null || bucket.isEmpty) continue;
    bucket.sort((a, b) => a.level.compareTo(b.level));

    Color? color;
    for (final level in bucket) {
      color = tryParseHexColor(level.color);
      if (color != null) break;
    }

    sections.add(LevelTierSection(
      tier: tier,
      levels: List.unmodifiable(bucket),
      color: color ?? tier.fallbackColor,
    ));
  }
  return sections;
}

/// Parses `#RRGGBB` / `RRGGBB` / `#AARRGGBB`; returns `null` when invalid.
Color? tryParseHexColor(String? hex) {
  if (hex == null) return null;
  final cleaned = hex.trim().replaceFirst('#', '');
  if (cleaned.length != 6 && cleaned.length != 8) return null;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return cleaned.length == 6 ? Color(0xFF000000 | value) : Color(value);
}

/// Black or white, whichever reads better on [background].
Color foregroundOn(Color background) {
  return background.computeLuminance() > 0.4
      ? const Color(0xFF09090B)
      : const Color(0xFFFFFFFF);
}
