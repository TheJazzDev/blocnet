import type { MiningPointLedger, Prisma } from '@prisma/client';
import { formatAtomicAmount } from '../tips/tip-amount.util';
import { BNP_DECIMALS } from '../tips/tip.constants';
import type {
  BnpAdjustmentActor,
  BnpAdjustmentBalances,
  BnpAdjustmentResponse,
} from './dto/bnp-adjustment-response.dto';

/**
 * F-66: what an admin adjustment stores in `MiningPointLedger.metadata`, and
 * how a ledger row becomes the wire shape. No schema change: reason, actor
 * and the before/after balances all live in the existing JSON column.
 */
export type AdjustmentLedgerMetadata = {
  kind: 'admin_adjustment';
  reason: string;
  actorId: string;
  idempotencyKey: string;
  balanceBefore: BnpAdjustmentBalances;
  balanceAfter: BnpAdjustmentBalances;
};

export function toBalances(
  claimedPoints: bigint,
  walletAtomic: bigint,
): BnpAdjustmentBalances {
  return {
    claimedPoints: claimedPoints.toString(),
    walletBalance: formatAtomicAmount(walletAtomic, BNP_DECIMALS),
  };
}

function asObject(value: Prisma.JsonValue | null): Record<string, unknown> {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function asBalances(value: unknown): BnpAdjustmentBalances | null {
  if (!value || typeof value !== 'object') return null;
  const { claimedPoints, walletBalance } = value as Record<string, unknown>;
  return typeof claimedPoints === 'string' && typeof walletBalance === 'string'
    ? { claimedPoints, walletBalance }
    : null;
}

export function readAdjustmentMetadata(
  row: Pick<MiningPointLedger, 'metadata'>,
) {
  const meta = asObject(row.metadata);
  return {
    reason: typeof meta.reason === 'string' ? meta.reason : '',
    actorId: typeof meta.actorId === 'string' ? meta.actorId : null,
    idempotencyKey:
      typeof meta.idempotencyKey === 'string' ? meta.idempotencyKey : null,
    balanceBefore: asBalances(meta.balanceBefore),
    balanceAfter: asBalances(meta.balanceAfter),
  };
}

export function toAdjustmentResponse(
  row: MiningPointLedger,
  actor: BnpAdjustmentActor | null,
  replayed: boolean,
): BnpAdjustmentResponse {
  const meta = readAdjustmentMetadata(row);
  return {
    id: row.id,
    userId: row.userId,
    amount: row.points,
    reason: meta.reason,
    actor,
    balanceBefore: meta.balanceBefore,
    balanceAfter: meta.balanceAfter,
    createdAt: row.createdAt,
    replayed,
  };
}
