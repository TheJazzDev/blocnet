/**
 * Lifetime BNP (Blocnet Point) mining totals, shared by the mining-admin
 * metrics and the wallet-admin health responses.
 *
 * Vocabulary (F-07): users mine BNP today. BNT (Blocnet Token) launches on
 * BSC and BNP converts to BNT at launch. MCR ("Mine Credits") was the
 * pre-BNP name and is retired; the `*Mcr` keys below are aliases kept only
 * so the console keeps working until it switches to the `*Bnp` keys.
 */
export interface LifetimeMiningTotals {
  /** Total BNP ever minted by hourly checkpoints. */
  lifetimeMinedBnp: number;
  /** BNP from checkpoints that have been claimed. */
  lifetimeClaimedBnp: number;
  /** BNP minted but not yet claimed; never negative. */
  lifetimeUnclaimedBnp: number;

  /**
   * @deprecated Same value as `lifetimeMinedBnp`; remove after console WS-G lands.
   */
  lifetimeMinedMcr: number;
  /**
   * @deprecated Same value as `lifetimeClaimedBnp`; remove after console WS-G lands.
   */
  lifetimeClaimedMcr: number;
  /**
   * @deprecated Same value as `lifetimeUnclaimedBnp`; remove after console WS-G lands.
   */
  lifetimeUnclaimedMcr: number;
}

/**
 * Builds the totals block from the raw `_sum.points` aggregates over
 * MiningHourlyCheckpoint (all rows vs. claimed rows).
 */
export function buildLifetimeMiningTotals(
  minedPoints: number | null | undefined,
  claimedPoints: number | null | undefined,
): LifetimeMiningTotals {
  const lifetimeMinedBnp = minedPoints ?? 0;
  const lifetimeClaimedBnp = claimedPoints ?? 0;
  const lifetimeUnclaimedBnp = Math.max(
    lifetimeMinedBnp - lifetimeClaimedBnp,
    0,
  );

  return {
    lifetimeMinedBnp,
    lifetimeClaimedBnp,
    lifetimeUnclaimedBnp,
    lifetimeMinedMcr: lifetimeMinedBnp,
    lifetimeClaimedMcr: lifetimeClaimedBnp,
    lifetimeUnclaimedMcr: lifetimeUnclaimedBnp,
  };
}
