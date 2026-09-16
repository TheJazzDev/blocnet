import { Prisma, TipAccountType, TipTransactionType } from '@prisma/client';
import { BNP_CURRENCY_CODE } from '../tips/tip.constants';

/**
 * BNP tip account movements for minted BNP (mining claims, quest rewards) and
 * their reversal (a revoked quest reward).
 *
 * Every balance change here writes a matching `TipTransaction` in the same
 * transaction (F-63), so the wallet's BNP activity explains the balance. The
 * row's `idempotencyKey` is unique, and each helper checks it first: calling
 * a helper twice with the same context moves the balance once.
 */

export const BNP_ATOMIC_MULTIPLIER = 1000n;

export const BNP_REWARD_CONTEXT = {
  miningClaim: 'mining_claim',
  questReward: 'quest_reward',
  questRewardRevoked: 'quest_reward_revoked',
} as const;

export type BnpLedgerContext = {
  contextType: string;
  contextId: string;
  idempotencyKey: string;
  metadata?: Prisma.InputJsonObject;
  /** Backfills only: date the row to the event it records. */
  createdAt?: Date;
};

export function miningClaimRewardContext(
  sessionId: string,
  extra: Pick<BnpLedgerContext, 'metadata' | 'createdAt'> = {},
): BnpLedgerContext {
  return {
    contextType: BNP_REWARD_CONTEXT.miningClaim,
    contextId: sessionId,
    idempotencyKey: `mining-claim:${sessionId}`,
    ...extra,
  };
}

/**
 * A quest reward is keyed by its submission. Auto-completed quests have no
 * submission, so they are keyed by the `MiningPointLedger` row the award
 * wrote, which is unique per award.
 */
export function questRewardContext(
  ref: { submissionId: string } | { ledgerId: string },
  extra: Pick<BnpLedgerContext, 'metadata' | 'createdAt'> = {},
): BnpLedgerContext {
  if ('submissionId' in ref) {
    return {
      contextType: BNP_REWARD_CONTEXT.questReward,
      contextId: ref.submissionId,
      idempotencyKey: `quest-reward:${ref.submissionId}`,
      ...extra,
    };
  }
  return {
    contextType: BNP_REWARD_CONTEXT.questReward,
    contextId: ref.ledgerId,
    idempotencyKey: `quest-reward:ledger:${ref.ledgerId}`,
    ...extra,
  };
}

/**
 * One key per submission is enough: a submission is revoked at most once
 * (the revoke flips `approved` -> `rejected` under a conditional update, and
 * nothing moves a submission back to `approved`).
 */
export function questRewardRevokedContext(
  submissionId: string,
  extra: Pick<BnpLedgerContext, 'metadata' | 'createdAt'> = {},
): BnpLedgerContext {
  return {
    contextType: BNP_REWARD_CONTEXT.questRewardRevoked,
    contextId: submissionId,
    idempotencyKey: `quest-reward-revoked:${submissionId}`,
    ...extra,
  };
}

export type BnpTipAccountTx = Pick<
  Prisma.TransactionClient,
  'tipCurrency' | 'tipAccount' | 'tipTransaction'
>;

function bnpAccountKey(userId: string) {
  return {
    accountType: TipAccountType.user,
    ownerRef: userId,
    currencyCode: BNP_CURRENCY_CODE,
  };
}

async function ledgerRowExists(
  tx: BnpTipAccountTx,
  idempotencyKey: string,
): Promise<boolean> {
  const existing = await tx.tipTransaction.findUnique({
    where: { idempotencyKey },
    select: { id: true },
  });
  return existing !== null;
}

function writeLedgerRow(
  tx: BnpTipAccountTx,
  input: {
    type: TipTransactionType;
    userId: string;
    accountId: string;
    amountAtomic: bigint;
    context: BnpLedgerContext;
  },
) {
  const { context } = input;
  // Minted and reversed BNP has no counterparty: sender and recipient are the
  // member's own account. Readers key on `type`/`contextType`, never on
  // sender vs recipient.
  return tx.tipTransaction.create({
    data: {
      type: input.type,
      senderAccountId: input.accountId,
      recipientAccountId: input.accountId,
      senderUserId: input.userId,
      recipientUserId: input.userId,
      currencyCode: BNP_CURRENCY_CODE,
      amountAtomic: input.amountAtomic,
      feeAtomic: 0n,
      totalDebitAtomic: 0n,
      contextType: context.contextType,
      contextId: context.contextId,
      idempotencyKey: context.idempotencyKey,
      ...(context.metadata ? { metadata: context.metadata } : {}),
      ...(context.createdAt ? { createdAt: context.createdAt } : {}),
    },
  });
}

export async function ensureBnpCurrency(tx: BnpTipAccountTx): Promise<void> {
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
}

/**
 * Credits mined or earned BNP to the member's BNP tip account and records it
 * as a `reward` row, so the wallet balance and `Profile.miningClaimedPoints`
 * move together. Every BNP payout uses this: cycle claims and quest rewards
 * (F-52, F-63). Returns the atomic amount credited (0 on a repeat call).
 */
export async function creditBnpTipAccount(
  tx: BnpTipAccountTx,
  userId: string,
  points: number,
  context: BnpLedgerContext,
): Promise<bigint> {
  const creditAtomic = BigInt(points) * BNP_ATOMIC_MULTIPLIER;
  if (creditAtomic <= 0n) {
    return 0n;
  }
  if (await ledgerRowExists(tx, context.idempotencyKey)) {
    return 0n;
  }

  await ensureBnpCurrency(tx);

  const account = await tx.tipAccount.upsert({
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
    select: { id: true },
  });

  await writeLedgerRow(tx, {
    type: TipTransactionType.reward,
    userId,
    accountId: account.id,
    amountAtomic: creditAtomic,
    context,
  });

  return creditAtomic;
}

/**
 * Reverses a BNP credit (a revoked quest reward), clamped at the current
 * balance because the member may already have tipped some of it away. The
 * `gte` guard means a concurrent spend can never drive the account negative.
 * Writes an `adjustment` row for the amount actually debited (none when 0).
 * Returns the atomic amount actually debited.
 */
export async function debitBnpTipAccount(
  tx: BnpTipAccountTx,
  userId: string,
  points: number,
  context: BnpLedgerContext,
): Promise<bigint> {
  const wantedAtomic = BigInt(Math.abs(points)) * BNP_ATOMIC_MULTIPLIER;
  if (wantedAtomic <= 0n) {
    return 0n;
  }
  if (await ledgerRowExists(tx, context.idempotencyKey)) {
    return 0n;
  }

  const account = await tx.tipAccount.findUnique({
    where: {
      accountType_ownerRef_currencyCode: bnpAccountKey(userId),
    },
    select: { id: true, balanceAtomic: true },
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
  if (debited.count === 0) {
    return 0n;
  }

  await writeLedgerRow(tx, {
    type: TipTransactionType.adjustment,
    userId,
    accountId: account.id,
    amountAtomic: debitAtomic,
    context,
  });

  return debitAtomic;
}
