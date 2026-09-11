/**
 * Lifetime mining totals in BNP (Blocnet Points).
 *
 * The API still serialises these as `lifetime*Mcr` (MCR was the retired name
 * for the mined unit). WS-H adds `lifetime*Bnp` aliases and later drops the
 * Mcr fields; every consumer reads through `toMiningTotals` so that rename is
 * a change to this file only.
 */
export interface MiningTotals {
  lifetimeMinedBnp: number;
  lifetimeClaimedBnp: number;
  lifetimeUnclaimedBnp: number;
  totalMiners: number;
}

export interface RawMiningTotals {
  lifetimeMinedBnp?: number;
  lifetimeClaimedBnp?: number;
  lifetimeUnclaimedBnp?: number;
  /** @deprecated legacy MCR field; prefer `lifetimeMinedBnp`. */
  lifetimeMinedMcr?: number;
  /** @deprecated legacy MCR field; prefer `lifetimeClaimedBnp`. */
  lifetimeClaimedMcr?: number;
  /** @deprecated legacy MCR field; prefer `lifetimeUnclaimedBnp`. */
  lifetimeUnclaimedMcr?: number;
  totalMiners: number;
}

export function toMiningTotals(raw: RawMiningTotals | null | undefined): MiningTotals | null {
  if (!raw) return null;
  return {
    lifetimeMinedBnp: raw.lifetimeMinedBnp ?? raw.lifetimeMinedMcr ?? 0,
    lifetimeClaimedBnp: raw.lifetimeClaimedBnp ?? raw.lifetimeClaimedMcr ?? 0,
    lifetimeUnclaimedBnp: raw.lifetimeUnclaimedBnp ?? raw.lifetimeUnclaimedMcr ?? 0,
    totalMiners: raw.totalMiners,
  };
}
