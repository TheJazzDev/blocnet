/**
 * Read-only planning for `backfill-bnp-reward-rows.ts`: finds the mining and
 * quest payouts that have no BNP `reward` row yet and decides, per payout,
 * whether the BNP tip account was ever credited.
 *
 * Nothing in this file writes.
 */
import { createHash } from 'node:crypto';
import { MiningPointSource, type PrismaClient } from '@prisma/client';
import {
  BNP_ATOMIC_MULTIPLIER,
  miningClaimRewardContext,
  questRewardContext,
  type BnpLedgerContext,
} from '../../src/mining/bnp-tip-account';
import { BNP_CURRENCY_CODE } from '../../src/tips/tip.constants';

export type PayoutKind = 'mining_claim' | 'quest_reward';

/**
 * - `row_only`: the balance already holds this BNP; write the ledger row.
 * - `credit_and_row` (F-64): the balance never received it; credit + row.
 * - `skip_reversed`: the reward was revoked before any BNP moved; net zero.
 * - `review`: the history is ambiguous; a human decides.
 */
export type PayoutAction =
  | 'row_only'
  | 'credit_and_row'
  | 'skip_reversed'
  | 'review';

export type PayoutPlan = {
  kind: PayoutKind;
  action: PayoutAction;
  why: string;
  ledgerId: string;
  userId: string;
  points: number;
  createdAt: Date;
  accountId: string | null;
  context: BnpLedgerContext;
};

type LedgerRow = {
  id: string;
  userId: string;
  sessionId: string | null;
  points: number;
  metadata: unknown;
  createdAt: Date;
};

type AccountRow = { id: string; ownerRef: string; createdAt: Date };

const CHUNK = 500;

function chunks<T>(items: T[]): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += CHUNK) {
    out.push(items.slice(i, i + CHUNK));
  }
  return out;
}

function meta(row: { metadata: unknown }): Record<string, unknown> {
  const value = row.metadata;
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function metaString(row: { metadata: unknown }, key: string): string | null {
  const value = meta(row)[key];
  return typeof value === 'string' && value.length > 0 ? value : null;
}

/**
 * The tipping_ledger_v1 migration (Feb 2026) created one account per profile
 * with id = uuid(md5('tip-user-mcr-' || profileId)) and a balance of
 * `miningClaimedPoints * 1000`, then the MCR currency was renamed to BNP. So
 * an account with that id already holds every quest reward granted before
 * the account's `createdAt`.
 */
export function seededAccountId(profileId: string): string {
  const hex = createHash('md5')
    .update(`tip-user-mcr-${profileId}`)
    .digest('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

async function existingKeys(
  prisma: PrismaClient,
  keys: string[],
): Promise<Set<string>> {
  const found = new Set<string>();
  for (const batch of chunks(keys)) {
    const rows = await prisma.tipTransaction.findMany({
      where: { idempotencyKey: { in: batch } },
      select: { idempotencyKey: true },
    });
    rows.forEach((row) => found.add(row.idempotencyKey));
  }
  return found;
}

async function bnpAccounts(
  prisma: PrismaClient,
  userIds: string[],
): Promise<Map<string, AccountRow>> {
  const map = new Map<string, AccountRow>();
  for (const batch of chunks([...new Set(userIds)])) {
    const rows = await prisma.tipAccount.findMany({
      where: {
        accountType: 'user',
        currencyCode: BNP_CURRENCY_CODE,
        ownerRef: { in: batch },
      },
      select: { id: true, ownerRef: true, createdAt: true },
    });
    rows.forEach((row) => map.set(row.ownerRef, row));
  }
  return map;
}

function userFilter(userIds: string[]) {
  return userIds.length > 0 ? { userId: { in: userIds } } : {};
}

/** (a) Claimed mining cycles: the claim path has always credited BNP. */
export async function planMiningClaims(
  prisma: PrismaClient,
  userIds: string[],
): Promise<{ plans: PayoutPlan[]; alreadyRecorded: number }> {
  const ledger: LedgerRow[] = await prisma.miningPointLedger.findMany({
    where: {
      source: MiningPointSource.cycle_claim,
      sessionId: { not: null },
      points: { gt: 0 },
      ...userFilter(userIds),
    },
    orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    select: {
      id: true,
      userId: true,
      sessionId: true,
      points: true,
      metadata: true,
      createdAt: true,
    },
  });

  const contexts = ledger.map((row) =>
    miningClaimRewardContext(row.sessionId as string, {
      createdAt: row.createdAt,
      metadata: { miningLedgerId: row.id, backfill: 'F-63' },
    }),
  );
  const recorded = await existingKeys(
    prisma,
    contexts.map((ctx) => ctx.idempotencyKey),
  );
  const accounts = await bnpAccounts(
    prisma,
    ledger.map((row) => row.userId),
  );

  const seen = new Set<string>();
  const plans: PayoutPlan[] = [];
  let alreadyRecorded = 0;
  ledger.forEach((row, index) => {
    const context = contexts[index];
    if (recorded.has(context.idempotencyKey)) {
      alreadyRecorded += 1;
      return;
    }
    const account = accounts.get(row.userId) ?? null;
    const duplicate = seen.has(context.idempotencyKey);
    seen.add(context.idempotencyKey);
    plans.push({
      kind: 'mining_claim',
      action: duplicate || !account ? 'review' : 'row_only',
      why: duplicate
        ? 'second cycle_claim ledger row for the same session'
        : account
          ? 'claim credited BNP; ledger row missing'
          : 'claimed but the member has no BNP account',
      ledgerId: row.id,
      userId: row.userId,
      points: row.points,
      createdAt: row.createdAt,
      accountId: account?.id ?? null,
      context,
    });
  });
  return { plans, alreadyRecorded };
}

/** Each reversal row is matched to at most one reward (`used`). */
function findReversal(
  reward: LedgerRow,
  reversals: LedgerRow[],
  used: Set<string>,
): LedgerRow | null {
  const submissionId = metaString(reward, 'questSubmissionId');
  const questId = metaString(reward, 'questId');
  const match = reversals.find((row) => {
    if (used.has(row.id) || row.userId !== reward.userId) return false;
    if (metaString(row, 'reversedLedgerId') === reward.id) return true;
    if (submissionId) {
      return metaString(row, 'questSubmissionId') === submissionId;
    }
    // Legacy reward without a submission id: the revoke matched on quest.
    return (
      questId !== null &&
      metaString(row, 'questId') === questId &&
      row.createdAt >= reward.createdAt
    );
  });
  if (match) used.add(match.id);
  return match ?? null;
}

/**
 * (b) Quest rewards. Before F-52 went live the quest path never touched the
 * tip account, so a pre-F-52 reward is uncredited unless the account was
 * seeded from `miningClaimedPoints` after it was granted.
 */
export async function planQuestRewards(
  prisma: PrismaClient,
  userIds: string[],
  creditedSince: Date,
): Promise<{ plans: PayoutPlan[]; alreadyRecorded: number }> {
  const rows: LedgerRow[] = await prisma.miningPointLedger.findMany({
    where: {
      source: MiningPointSource.quest_reward,
      ...userFilter(userIds),
    },
    orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    select: {
      id: true,
      userId: true,
      sessionId: true,
      points: true,
      metadata: true,
      createdAt: true,
    },
  });
  const rewards = rows.filter((row) => row.points > 0);
  const reversals = rows.filter((row) => row.points < 0);

  const contexts = rewards.map((row) => {
    const submissionId = metaString(row, 'questSubmissionId');
    return questRewardContext(
      submissionId ? { submissionId } : { ledgerId: row.id },
      {
        createdAt: row.createdAt,
        metadata: {
          questId: metaString(row, 'questId'),
          questSlug: metaString(row, 'questSlug'),
          questTitle: metaString(row, 'questTitle'),
          miningLedgerId: row.id,
          backfill: 'F-63',
        },
      },
    );
  });
  const recorded = await existingKeys(
    prisma,
    contexts.map((ctx) => ctx.idempotencyKey),
  );
  const accounts = await bnpAccounts(
    prisma,
    rewards.map((row) => row.userId),
  );

  const submissionIds = rewards
    .map((row) => metaString(row, 'questSubmissionId'))
    .filter((id): id is string => id !== null);
  const submissions = new Map<string, string>();
  for (const batch of chunks(submissionIds)) {
    const found = await prisma.questSubmission.findMany({
      where: { id: { in: batch } },
      select: { id: true, verificationStatus: true },
    });
    found.forEach((row) => submissions.set(row.id, row.verificationStatus));
  }

  const seen = new Set<string>();
  const usedReversals = new Set<string>();
  const plans: PayoutPlan[] = [];
  let alreadyRecorded = 0;
  rewards.forEach((row, index) => {
    const context = contexts[index];
    if (recorded.has(context.idempotencyKey)) {
      alreadyRecorded += 1;
      return;
    }
    const account = accounts.get(row.userId) ?? null;
    const plan = (action: PayoutAction, why: string): PayoutPlan => ({
      kind: 'quest_reward',
      action,
      why,
      ledgerId: row.id,
      userId: row.userId,
      points: row.points,
      createdAt: row.createdAt,
      accountId: account?.id ?? null,
      context,
    });

    if (seen.has(context.idempotencyKey)) {
      plans.push(plan('review', 'second reward ledger row for one submission'));
      return;
    }
    seen.add(context.idempotencyKey);

    if (row.createdAt >= creditedSince) {
      plans.push(
        account
          ? plan('row_only', 'granted after F-52: credited, row missing')
          : plan('review', 'granted after F-52 but no BNP account exists'),
      );
      return;
    }

    const reversal = findReversal(row, reversals, usedReversals);
    if (reversal) {
      plans.push(
        reversal.createdAt >= creditedSince
          ? plan(
              'review',
              'uncredited reward revoked after F-52: the revoke debited BNP that was never credited',
            )
          : plan(
              'skip_reversed',
              'granted and revoked before F-52; no BNP moved',
            ),
      );
      return;
    }

    const submissionId = metaString(row, 'questSubmissionId');
    const status = submissionId ? submissions.get(submissionId) : undefined;
    if (submissionId && status !== 'approved') {
      plans.push(
        plan(
          'review',
          `submission is ${status ?? 'missing'} but no reversal ledger row exists`,
        ),
      );
      return;
    }

    const seeded =
      account !== null &&
      account.id === seededAccountId(row.userId) &&
      row.createdAt < account.createdAt;
    plans.push(
      seeded
        ? plan(
            'row_only',
            'granted before the Feb 2026 seed that copied miningClaimedPoints',
          )
        : plan(
            'credit_and_row',
            'granted before F-52; never reached the tip account',
          ),
    );
  });
  return { plans, alreadyRecorded };
}

export function atomic(points: number): bigint {
  return BigInt(points) * BNP_ATOMIC_MULTIPLIER;
}
