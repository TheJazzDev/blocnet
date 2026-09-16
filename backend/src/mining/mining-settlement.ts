import { Prisma, TipAccountType } from '@prisma/client';
import { BNP_CURRENCY_CODE } from '../tips/tip.constants';

/**
 * Shared, transaction-level settlement primitives for a mining cycle.
 *
 * A cycle has exactly two terminal states and both are written here so that
 * every caller (the live `claim()` path, the expiry reconciler, and the F-39
 * one-off backfill) produces byte-identical ledger/balance effects:
 *
 *  - paid      -> `MiningSession.claimedAt` + checkpoints claimed + ledger row
 *                 + `Profile.miningClaimedPoints` + BNP tip account credit
 *  - forfeited -> `MiningSession.expiredAt` + checkpoints expired, no payout
 */

export const BNP_ATOMIC_MULTIPLIER = 1000n;

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

  await creditBnpTipAccount(tx, userId, claimPoints);
}

type TipAccountTx = Pick<Prisma.TransactionClient, 'tipCurrency' | 'tipAccount'>;

function bnpAccountKey(userId: string) {
  return {
    accountType: TipAccountType.user,
    ownerRef: userId,
    currencyCode: BNP_CURRENCY_CODE,
  };
}

/**
 * Credits mined or earned BNP to the member's BNP tip account, so the wallet
 * balance and `Profile.miningClaimedPoints` move together. Every BNP payout
 * uses this: cycle claims and quest rewards (F-52).
 */
export async function creditBnpTipAccount(
  tx: TipAccountTx,
  userId: string,
  points: number,
): Promise<void> {
  const creditAtomic = BigInt(points) * BNP_ATOMIC_MULTIPLIER;
  if (creditAtomic <= 0n) {
    return;
  }

  await tx.tipCurrency.upsert({
    where: { code: BNP_CURRENCY_CODE },
    update: {},
    create: {
      code: BNP_CURRENCY_CODE,
      name: 'Blocnet Points',
      symbol: 'BNP',
      decimals: 3,
      kind: 'points',
      isEnabled: true,
      isActiveTippingCurrency: true,
    },
  });

  await tx.tipAccount.upsert({
    where: {
      accountType_ownerRef_currencyCode: bnpAccountKey(userId),
    },
    update: {
      userId,
      balanceAtomic: {
        increment: creditAtomic,
      },
    },
    create: {
      ...bnpAccountKey(userId),
      userId,
      balanceAtomic: creditAtomic,
    },
  });
}

/**
 * Reverses a BNP credit (a revoked quest reward), clamped at the current
 * balance because the member may already have tipped some of it away. The
 * `gte` guard means a concurrent spend can never drive the account negative.
 * Returns the atomic amount actually debited.
 */
export async function debitBnpTipAccount(
  tx: TipAccountTx,
  userId: string,
  points: number,
): Promise<bigint> {
  const wantedAtomic = BigInt(Math.abs(points)) * BNP_ATOMIC_MULTIPLIER;
  if (wantedAtomic <= 0n) {
    return 0n;
  }

  const account = await tx.tipAccount.findUnique({
    where: {
      accountType_ownerRef_currencyCode: bnpAccountKey(userId),
    },
    select: { balanceAtomic: true },
  });
  if (!account) {
    return 0n;
  }

  const debitAtomic =
    account.balanceAtomic < wantedAtomic ? account.balanceAtomic : wantedAtomic;
  if (debitAtomic <= 0n) {
    return 0n;
  }

  const debited = await tx.tipAccount.updateMany({
    where: {
      ...bnpAccountKey(userId),
      balanceAtomic: { gte: debitAtomic },
    },
    data: {
      balanceAtomic: { decrement: debitAtomic },
    },
  });

  return debited.count > 0 ? debitAtomic : 0n;
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
