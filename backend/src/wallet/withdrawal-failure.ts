/**
 * One place that decides what a member is told when a withdrawal fails, and
 * keeps the operational detail (raw RPC/custody errors, missing config, tx
 * hashes) away from them.
 *
 * - New failures store only the safe message in `WithdrawalRequest.failureReason`
 *   and in the revert ledger entry's `reason`; the detail goes to the logs, the
 *   audit log, and the ledger entry's `internalDetail` (admin only).
 * - Rows written before this split still hold the raw text, so every
 *   member-facing mapper sanitises on read as well.
 */
import { LedgerReason, Prisma, WithdrawalStatus } from '@prisma/client';

export const WITHDRAWAL_FAILED_MESSAGE =
  'Withdrawal failed. The amount is back in your wallet.';

/** Ledger metadata key that holds the operator-only failure detail. */
export const INTERNAL_DETAIL_KEY = 'internalDetail';

/** Marks a release entry written by the settlement revert path. */
export const REVERT_KIND = 'settlement_revert';

/**
 * Member view of a withdrawal's failure fields. A stored failure reason is
 * never shown as written; a reverted withdrawal never carries a reject reason
 * (only an admin rejection does, and that one is written for the member).
 */
export function toMemberWithdrawalFailure(withdrawal: {
  status: WithdrawalStatus;
  failureReason: string | null;
  rejectReason: string | null;
}): { failureReason: string | null; rejectReason: string | null } {
  const reverted = withdrawal.status === WithdrawalStatus.reverted;
  const hasFailure =
    reverted || (withdrawal.failureReason?.trim().length ?? 0) > 0;

  return {
    failureReason: hasFailure ? WITHDRAWAL_FAILED_MESSAGE : null,
    rejectReason: reverted ? null : withdrawal.rejectReason,
  };
}

/**
 * Member view of a ledger entry's metadata. Drops the internal detail and,
 * on a settlement revert (new or legacy), replaces the stored reason with the
 * safe message. An admin rejection's reason is left as the admin wrote it.
 */
export function toMemberLedgerMetadata(
  entry: { reason: LedgerReason; idempotencyKey: string },
  metadata: Prisma.JsonObject | null,
): Prisma.JsonObject | null {
  if (!metadata) {
    return null;
  }

  const rest: Prisma.JsonObject = { ...metadata };
  delete rest[INTERNAL_DETAIL_KEY];

  if (isSettlementRevert(entry, metadata) && 'reason' in rest) {
    return { ...rest, reason: WITHDRAWAL_FAILED_MESSAGE };
  }

  return rest;
}

/**
 * Operator view of why a withdrawal failed: the detail kept on the revert
 * ledger entry, falling back to the row's own text (which is the raw detail
 * on rows written before the split).
 */
export function resolveAdminFailureDetail(
  failureReason: string | null,
  releaseEntryMetadata: Prisma.JsonValue | null | undefined,
): string | null {
  if (
    releaseEntryMetadata &&
    typeof releaseEntryMetadata === 'object' &&
    !Array.isArray(releaseEntryMetadata)
  ) {
    const detail = releaseEntryMetadata[INTERNAL_DETAIL_KEY];
    if (typeof detail === 'string' && detail.trim().length > 0) {
      return detail;
    }
  }
  return failureReason;
}

function isSettlementRevert(
  entry: { reason: LedgerReason; idempotencyKey: string },
  metadata: Prisma.JsonObject,
): boolean {
  if (entry.reason !== LedgerReason.withdrawal_reject_release) {
    return false;
  }
  if (metadata.kind === REVERT_KIND) {
    return true;
  }
  // Legacy rows: the revert path keys on ":revert" and is the only release
  // writer that records the asset; the admin rejection does neither.
  return entry.idempotencyKey.endsWith(':revert') || 'asset' in metadata;
}
