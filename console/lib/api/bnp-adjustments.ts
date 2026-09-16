/**
 * F-66: pure helpers for the "Adjust BNP" dialog. The backend is the source
 * of truth (it re-checks every rule); these only drive the form and the
 * before -> after preview.
 */
import type { AdminUserDetail } from "./server-types-admin-users";

export const MAX_BNP_ADJUSTMENT = 1_000_000;
export const REASON_MIN = 10;
export const REASON_MAX = 500;

const BNP_DECIMALS = 3;
const ATOMIC = BigInt(10) ** BigInt(BNP_DECIMALS);

export type AdjustmentDirection = "add" | "remove";

export type BnpBalances = {
  /** Whole BNP (`Profile.miningClaimedPoints`). */
  claimedPoints: bigint;
  /** Wallet balance in atomic units (3 decimals). */
  walletAtomic: bigint;
};

function toBigInt(value: string | null | undefined): bigint {
  try {
    return value ? BigInt(value) : BigInt(0);
  } catch {
    return BigInt(0);
  }
}

/**
 * The member's current balances. A member with no BNP wallet yet gets one
 * seeded from their claimed points, so that is the wallet "before" value.
 */
export function currentBnpBalances(user: AdminUserDetail): BnpBalances {
  const claimedPoints = toBigInt(user.mining.claimedTotalPoints);
  const account = user.tips?.accounts?.find(
    (entry) => entry.accountType === "user" && entry.currencyCode === "BNP",
  );
  return {
    claimedPoints,
    walletAtomic: account ? toBigInt(account.balanceAtomic) : claimedPoints * ATOMIC,
  };
}

export function formatAtomicBnp(value: bigint): string {
  const sign = value < BigInt(0) ? "-" : "";
  const abs = value < BigInt(0) ? -value : value;
  const whole = (abs / ATOMIC).toLocaleString("en-US");
  const fraction = (abs % ATOMIC).toString().padStart(BNP_DECIMALS, "0").replace(/0+$/, "");
  return `${sign}${whole}${fraction ? `.${fraction}` : ""}`;
}

export function formatWholeBnp(value: bigint): string {
  return value.toLocaleString("en-US");
}

/** Parses the amount field: a positive whole number within the cap, or null. */
export function parseAdjustmentAmount(raw: string): number | null {
  const trimmed = raw.trim();
  if (!/^\d+$/.test(trimmed)) return null;
  const value = Number(trimmed);
  return value >= 1 && value <= MAX_BNP_ADJUSTMENT ? value : null;
}

export function signedAmount(direction: AdjustmentDirection, amount: number): number {
  return direction === "remove" ? -amount : amount;
}

export function previewAdjustment(before: BnpBalances, signed: number): BnpBalances {
  const delta = BigInt(signed);
  return {
    claimedPoints: before.claimedPoints + delta,
    walletAtomic: before.walletAtomic + delta * ATOMIC,
  };
}

/** First problem with the form, or null when it can go to confirmation. */
export function validateAdjustmentForm(input: {
  direction: AdjustmentDirection;
  amountRaw: string;
  reason: string;
  before: BnpBalances;
}): string | null {
  const amount = parseAdjustmentAmount(input.amountRaw);
  if (amount === null) {
    return `Enter a whole number between 1 and ${MAX_BNP_ADJUSTMENT.toLocaleString("en-US")}.`;
  }
  const reasonLength = input.reason.trim().length;
  if (reasonLength < REASON_MIN || reasonLength > REASON_MAX) {
    return `Reason must be ${REASON_MIN}–${REASON_MAX} characters.`;
  }
  const after = previewAdjustment(input.before, signedAmount(input.direction, amount));
  if (after.claimedPoints < BigInt(0) || after.walletAtomic < BigInt(0)) {
    return "This would take the member's balance below zero.";
  }
  return null;
}
