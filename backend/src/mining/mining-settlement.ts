import { Prisma } from '@prisma/client';
import {
  creditBnpTipAccount,
  miningClaimRewardContext,
} from './bnp-tip-account';

export {
  BNP_ATOMIC_MULTIPLIER,
  creditBnpTipAccount,
  debitBnpTipAccount,
} from './bnp-tip-account';

/**
 * Shared, transaction-level settlement primitives for a mining cycle.
 *
 * A cycle has exactly two terminal states and both are written here so that
 * every caller (the live `claim()` path, the expiry reconciler, and the F-39
 * one-off backfill) produces byte-identical ledger/balance effects:
 *
 *  - paid      -> `MiningSession.claimedAt` + checkpoints claimed + ledger row
 *                 + `Profile.miningClaimedPoints` + BNP tip account credit
 *                 + `reward` TipTransaction (F-63)
 *  - forfeited -> `MiningSession.expiredAt` + checkpoints expired, no payout
 */

export type ClaimWindowConfig = {
  claimWindowHours: number;
};

export type SettleableSession = {
  id: string;
  startsAt: Date;
  endsAt: Date;
  basePointsPerCycle: number;
  effectivePointsPerCycle: number;
  boostBpsSnapshot: number;
  activeReferralsSnapshot: number;
};

export type ClaimSettlementInput = {
  userId: string;
  session: SettleableSession;
  claimedAt: Date;
  claimPoints: number;
  checkpointCount: number;
  /**
   * Extra metadata merged into the `MiningPointLedger` row. The F-39 backfill
   * uses this to stamp its rows so the one-off grant stays traceable and
   * reversible.
   */
  extraLedgerMetadata?: Record<string, unknown>;
  /**
   * Pay out a cycle that has already been forfeited, clearing `expiredAt` so
   * the paid/forfeited invariant still holds. Only the F-39 backfill sets
   * this: the live claim path must never resurrect a forfeited cycle.
   *
   * Idempotency is unaffected — the update is still guarded on
   * `claimedAt: null`, so a second run awards nothing.
   */
  reclaimForfeited?: boolean;
};

export class MiningSessionAlreadySettledError extends Error {
  constructor(readonly sessionId: string) {
    super(`Mining session ${sessionId} has already been settled`);
    this.name = 'MiningSessionAlreadySettledError';
  }
}

export function computeClaimDeadline(
  endsAt: Date,
  config: ClaimWindowConfig,
): Date {
  const claimWindowMs = Math.max(config.claimWindowHours, 0) * 60 * 60 * 1000;
  return new Date(endsAt.getTime() + claimWindowMs);
}

/** A cycle is claimable once it has ended and while its window is still open. */
export function isClaimable(
  session: { endsAt: Date },
  asOf: Date,
  config: ClaimWindowConfig,
): boolean {
  return (
    session.endsAt.getTime() <= asOf.getTime() &&
    !isClaimWindowExpired(session, asOf, config)
  );
}

export function isClaimWindowExpired(
  session: { endsAt: Date },
  asOf: Date,
  config: ClaimWindowConfig,
): boolean {
  return (
    asOf.getTime() > computeClaimDeadline(session.endsAt, config).getTime()
  );
}

/**
 * Points a claim pays out: the sum of the cycle's unsettled hourly accrual,
 * falling back to the snapshotted cycle value when no checkpoint rows exist.
 */
export function resolveClaimPoints(
  checkpointPoints: number | null | undefined,
  session: Pick<SettleableSession, 'effectivePointsPerCycle'>,
): number {
  if (checkpointPoints != null && checkpointPoints > 0) {
    return checkpointPoints;
  }

  return Math.max(session.effectivePointsPerCycle, 0);
}

/**
 * Pays out one cycle inside an open transaction. Guarded on
 * `claimedAt: null, expiredAt: null` so concurrent callers (and a re-run of the
 * backfill) can never double-award.
 */
export async function applyClaimSettlement(
  tx: Prisma.TransactionClient,
  input: ClaimSettlementInput,
): Promise<void> {
  const { userId, session, claimedAt, claimPoints, checkpointCount } = input;

  const reclaim = input.reclaimForfeited === true;

  const updated = await tx.miningSession.updateMany({
    where: {
      id: session.id,
      claimedAt: null,
      ...(reclaim ? {} : { expiredAt: null }),
    },
    data: {
      claimedAt,
      ...(reclaim ? { expiredAt: null } : {}),
    },
  });

  if (updated.count === 0) {
    throw new MiningSessionAlreadySettledError(session.id);
  }

  await tx.miningHourlyCheckpoint.updateMany({
    where: {
      sessionId: session.id,
      claimedAt: null,
      ...(reclaim ? {} : { expiredAt: null }),
    },
    data: {
      claimedAt,
      ...(reclaim ? { expiredAt: null } : {}),
    },
  });

  await tx.miningPointLedger.create({
    data: {
      userId,
      sessionId: session.id,
      source: 'cycle_claim',
      points: claimPoints,
      metadata: {
        startsAt: session.startsAt.toISOString(),
        endsAt: session.endsAt.toISOString(),
        basePointsPerCycle: session.basePointsPerCycle,
        hourlyCheckpointCount: checkpointCount,
        boostBpsSnapshot: session.boostBpsSnapshot,
        activeReferralsSnapshot: session.activeReferralsSnapshot,
        ...(input.extraLedgerMetadata ?? {}),
      },
    },
  });

  await tx.profile.update({
    where: { id: userId },
    data: {
      miningClaimedPoints: {
        increment: BigInt(claimPoints),
      },
    },
  });

  await creditBnpTipAccount(
    tx,
    userId,
    claimPoints,
    miningClaimRewardContext(session.id),
  );
}

/**
 * Forfeits one cycle inside an open transaction: no points move, but the
 * session and its accrual both reach a terminal state so they stop being
 * re-selected as "unclaimed" forever (the F-39 deadlock).
 */
export async function applyExpirySettlement(
  tx: Prisma.TransactionClient,
  input: { sessionId: string; expiredAt: Date },
): Promise<boolean> {
  const updated = await tx.miningSession.updateMany({
    where: {
      id: input.sessionId,
      claimedAt: null,
      expiredAt: null,
    },
    data: {
      expiredAt: input.expiredAt,
    },
  });

  if (updated.count === 0) {
    return false;
  }

  await tx.miningHourlyCheckpoint.updateMany({
    where: {
      sessionId: input.sessionId,
      claimedAt: null,
      expiredAt: null,
    },
    data: {
      expiredAt: input.expiredAt,
    },
  });

  return true;
}
