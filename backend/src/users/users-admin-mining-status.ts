import { isClaimable } from '../mining/mining-settlement';

export type AdminMiningSessionStatus =
  | 'running'
  | 'claimable'
  | 'claimed'
  | 'expired';

/** Claim window used when no MiningConfig row exists (schema default). */
export const DEFAULT_CLAIM_WINDOW_HOURS = 48;

/**
 * Status of a mining session as shown to admins. A cycle is only
 * "claimable" while the mining module would actually pay it out; one that
 * was forfeited (`expiredAt`) or whose claim window has closed is "expired".
 */
export function deriveAdminMiningSessionStatus(
  session: { endsAt: Date; claimedAt: Date | null; expiredAt: Date | null },
  asOf: Date,
  claimWindowHours: number,
): AdminMiningSessionStatus {
  if (session.claimedAt) {
    return 'claimed';
  }
  if (session.expiredAt) {
    return 'expired';
  }
  if (session.endsAt.getTime() > asOf.getTime()) {
    return 'running';
  }
  return isClaimable(session, asOf, { claimWindowHours })
    ? 'claimable'
    : 'expired';
}
