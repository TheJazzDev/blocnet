/**
 * Level tier helpers. Levels come in five tiers of three:
 * 1-3 Iron, 4-6 Jade, 7-9 Amethyst, 10-12 Gold, 13-15 Ruby.
 * Each level's `color` field normally holds its tier hex; we prefer it when valid
 * and fall back to the tier colour derived from the level number.
 */

export type LevelTierName = "Iron" | "Jade" | "Amethyst" | "Gold" | "Ruby";

export interface LevelTier {
  name: LevelTierName;
  color: string;
  minLevel: number;
  maxLevel: number;
}

export const LEVEL_TIERS: readonly LevelTier[] = [
  { name: "Iron", color: "#8A96A8", minLevel: 1, maxLevel: 3 },
  { name: "Jade", color: "#2AA876", minLevel: 4, maxLevel: 6 },
  { name: "Amethyst", color: "#8B5CF6", minLevel: 7, maxLevel: 9 },
  { name: "Gold", color: "#F0B429", minLevel: 10, maxLevel: 12 },
  { name: "Ruby", color: "#E23D4A", minLevel: 13, maxLevel: 15 },
];

const HEX_COLOR_PATTERN = /^#(?:[0-9a-f]{3}|[0-9a-f]{6})$/i;

export function isHexColor(value: string | null | undefined): value is string {
  return typeof value === "string" && HEX_COLOR_PATTERN.test(value.trim());
}

/** Tier for a level number. Out-of-range values clamp to the first/last tier. */
export function getLevelTier(level: number): LevelTier {
  const first = LEVEL_TIERS[0];
  const last = LEVEL_TIERS[LEVEL_TIERS.length - 1];
  if (!Number.isFinite(level) || level < first.minLevel) return first;
  if (level > last.maxLevel) return last;
  return (
    LEVEL_TIERS.find((tier) => level >= tier.minLevel && level <= tier.maxLevel) ??
    first
  );
}

export interface LevelColorSource {
  level: number;
  color?: string | null;
}

/** Colour for a level, preferring its own `color` field when it is a valid hex. */
export function getLevelColor(source: LevelColorSource): string {
  if (isHexColor(source.color)) return source.color.trim();
  return getLevelTier(source.level).color;
}

export function formatTierRange(tier: LevelTier): string {
  return `Levels ${tier.minLevel}–${tier.maxLevel}`;
}

/** Translucent version of a colour for tints (uses CSS color-mix). */
export function tintColor(color: string, percent: number): string {
  return `color-mix(in srgb, ${color} ${percent}%, transparent)`;
}

export interface LevelTierGroup<T> {
  tier: LevelTier;
  levels: T[];
}

/**
 * Groups levels by tier, in tier order. Within a tier, levels are sorted by
 * `sortOrder` (when present) then by level number. Empty tiers are omitted.
 */
export function groupLevelsByTier<
  T extends { level: number; sortOrder?: number },
>(levels: readonly T[]): LevelTierGroup<T>[] {
  const byTier = new Map<LevelTierName, T[]>();
  for (const level of levels) {
    const tier = getLevelTier(level.level);
    const bucket = byTier.get(tier.name) ?? [];
    bucket.push(level);
    byTier.set(tier.name, bucket);
  }

  return LEVEL_TIERS.flatMap((tier) => {
    const bucket = byTier.get(tier.name);
    if (!bucket || bucket.length === 0) return [];
    const sorted = [...bucket].sort(
      (a, b) =>
        (a.sortOrder ?? 0) - (b.sortOrder ?? 0) || a.level - b.level,
    );
    return [{ tier, levels: sorted }];
  });
}
