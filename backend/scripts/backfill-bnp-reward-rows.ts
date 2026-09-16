/**
 * F-63 / F-64 one-off backfill: give past BNP payouts their ledger rows, and
 * pay the quest rewards that never reached the BNP tip account.
 *
 * !!! PART (b) CHANGES MEMBER BALANCES. IT NEEDS THE OWNER'S EXPLICIT OK
 * !!! BEFORE IT RUNS WITH --apply ON PRODUCTION.
 *
 * Background
 * ----------
 * Mining claims and quest rewards credited the BNP `TipAccount` without a
 * `TipTransaction` (fixed in F-63), so wallet activity never explained the
 * balance. Separately, until F-52 the quest path never credited the tip
 * account at all (F-64), so those members are short the BNP their
 * `miningClaimedPoints` says they earned.
 *
 * What it does
 * ------------
 * (a) Rows only, no balance change: a `reward` row for every paid mining
 *     cycle, and for every quest reward whose BNP is already in the balance
 *     (granted after F-52 went live, or before the Feb 2026 seed that copied
 *     `miningClaimedPoints` into the accounts).
 * (b) F-64, balance + row: quest rewards granted before F-52 that never
 *     reached the tip account. Credited through `creditBnpTipAccount`, the
 *     same helper the live quest path uses. "Never credited" means: granted
 *     before `--credited-since`, not revoked, submission still approved, and
 *     not covered by the Feb 2026 seed (see scripts/bnp-reward-backfill/plan.ts).
 * Anything ambiguous is printed as REVIEW and left alone.
 *
 * Safety
 * ------
 * - Dry run unless `--apply` is passed.
 * - Idempotent: every row uses the live idempotency key
 *   (`mining-claim:<sessionId>`, `quest-reward:<submissionId>`, or
 *   `quest-reward:ledger:<ledgerId>`), and the helpers check it before moving
 *   anything, so a re-run finds nothing to do.
 * - Rows are dated to the payout they record, and carry `metadata.backfill`.
 * - Every (b) credit also writes a `bnp.reward.backfill` audit row.
 *
 * Usage
 * -----
 *   cd backend
 *   bun run bnp:backfill-reward-rows                      # dry run (default)
 *   bun run bnp:backfill-reward-rows -- --part=a --apply  # rows only
 *   bun run bnp:backfill-reward-rows -- --apply           # (a) + (b); OWNER OK FIRST
 *
 * Flags: `--part=a|b|all` (default all), `--user=<uuid[,uuid]>`,
 * `--credited-since=<ISO>`: when F-52 (quest BNP credit) went live in THIS
 * environment. Defaults to the F-52 commit time, which is right for local
 * dev. On production pass the F-52 deploy time: a quest reward granted
 * before it is treated as uncredited.
 *
 * Production
 * ----------
 *   1. Deploy F-63 first (the live paths must already write rows).
 *   2. Dry run against production; read the plan, especially CREDIT + REVIEW.
 *   3. Run `--part=a --apply` (no balance change).
 *   4. Only with the owner's explicit OK: `--part=b --apply`.
 *   5. Re-run the dry run: it must report nothing to write.
 */
import { PrismaPg } from '@prisma/adapter-pg';
import { Prisma, PrismaClient, TipTransactionType } from '@prisma/client';
import { config as loadEnv } from 'dotenv';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { Pool } from 'pg';
import { creditBnpTipAccount } from '../src/mining/bnp-tip-account';
import { BNP_CURRENCY_CODE } from '../src/tips/tip.constants';
import {
  atomic,
  planMiningClaims,
  planQuestRewards,
  type PayoutAction,
  type PayoutPlan,
} from './bnp-reward-backfill/plan';

loadEnv({ quiet: true });
loadEnv({ path: '.env.local', override: true, quiet: true });

const fallbackEnvPath = join(process.cwd(), 'backend/.env.local');
if (existsSync(fallbackEnvPath)) {
  loadEnv({ path: fallbackEnvPath, override: true, quiet: true });
}

/** F-52 commit (8cd66e1), 2026-09-16 12:55:30 +0100. */
const F52_COMMITTED_AT = new Date('2026-09-16T11:55:30.000Z');
const AUDIT_ACTION = 'bnp.reward.backfill';
const TX_OPTIONS = { timeout: 60_000, maxWait: 30_000 };

const BALANCE_WARNING = [
  '!!! Part (b) CHANGES MEMBER BALANCES (F-64).',
  "!!! It needs the OWNER'S EXPLICIT OK before it runs with --apply on production.",
];

type Part = 'a' | 'b' | 'all';

type CliOptions = {
  apply: boolean;
  part: Part;
  userIds: string[];
  creditedSince: Date;
};

function parseArgs(argv: string[]): CliOptions {
  const get = (name: string): string | undefined => {
    const inline = argv.find((arg) => arg.startsWith(`--${name}=`));
    if (inline) return inline.split('=').slice(1).join('=').trim();
    const index = argv.indexOf(`--${name}`);
    if (index >= 0) {
      const next = argv[index + 1];
      if (next && !next.startsWith('--')) return next.trim();
    }
    return undefined;
  };

  const part = (get('part') ?? 'all') as Part;
  if (!['a', 'b', 'all'].includes(part)) {
    throw new Error(`--part must be a, b or all (got "${part}")`);
  }
  const sinceRaw = get('credited-since');
  const creditedSince = sinceRaw ? new Date(sinceRaw) : F52_COMMITTED_AT;
  if (Number.isNaN(creditedSince.getTime())) {
    throw new Error(`--credited-since is not a date: "${sinceRaw}"`);
  }

  return {
    apply: argv.includes('--apply'),
    part,
    userIds: (get('user') ?? '')
      .split(',')
      .map((value) => value.trim())
      .filter((value) => value.length > 0),
    creditedSince,
  };
}

function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2002'
  );
}

/** (a) A row for BNP that is already in the balance. */
async function writeRowOnly(
  prisma: PrismaClient,
  plan: PayoutPlan,
): Promise<boolean> {
  const { context } = plan;
  try {
    await prisma.tipTransaction.create({
      data: {
        type: TipTransactionType.reward,
        senderAccountId: plan.accountId as string,
        recipientAccountId: plan.accountId as string,
        senderUserId: plan.userId,
        recipientUserId: plan.userId,
        currencyCode: BNP_CURRENCY_CODE,
        amountAtomic: atomic(plan.points),
        feeAtomic: 0n,
        totalDebitAtomic: 0n,
        contextType: context.contextType,
        contextId: context.contextId,
        idempotencyKey: context.idempotencyKey,
        metadata: context.metadata,
        createdAt: context.createdAt,
      },
    });
    return true;
  } catch (error) {
    // Written concurrently (or by a previous run): nothing to do.
    if (isUniqueViolation(error)) return false;
    throw error;
  }
}

/** (b) Credit the balance and write the row, in one transaction. */
async function creditAndWriteRow(
  prisma: PrismaClient,
  plan: PayoutPlan,
  ranAt: Date,
): Promise<boolean> {
  const context = {
    ...plan.context,
    metadata: {
      ...plan.context.metadata,
      backfill: 'F-64',
      backfillRanAt: ranAt.toISOString(),
    },
  };
  const credited = await prisma.$transaction(
    (tx) => creditBnpTipAccount(tx, plan.userId, plan.points, context),
    TX_OPTIONS,
  );
  if (credited <= 0n) return false;

  await prisma.auditLog.create({
    data: {
      actorId: plan.userId,
      action: AUDIT_ACTION,
      resourceType: 'mining_point_ledger',
      resourceId: plan.ledgerId,
      metadata: {
        backfill: 'F-64',
        reason:
          'Quest reward granted before F-52 never reached the BNP tip account.',
        points: plan.points,
        creditedAtomic: credited.toString(),
        idempotencyKey: context.idempotencyKey,
        grantedAt: plan.createdAt.toISOString(),
        ranAt: ranAt.toISOString(),
      },
    },
  });
  return true;
}

function actionLabel(action: PayoutAction): string {
  switch (action) {
    case 'row_only':
      return 'ROW   ';
    case 'credit_and_row':
      return 'CREDIT';
    case 'skip_reversed':
      return 'SKIP  ';
    case 'review':
      return 'REVIEW';
  }
}

function printPlan(plan: PayoutPlan) {
  console.log(
    `  ${actionLabel(plan.action)} ${plan.kind.padEnd(12)} ${String(plan.points).padStart(6)} BNP  ` +
      `user=${plan.userId} key=${plan.context.idempotencyKey} ` +
      `at=${plan.createdAt.toISOString()}  (${plan.why})`,
  );
}

function summarise(
  label: string,
  plans: PayoutPlan[],
  alreadyRecorded: number,
) {
  const count = (action: PayoutAction) =>
    plans.filter((plan) => plan.action === action);
  const points = (rows: PayoutPlan[]) =>
    rows.reduce((total, plan) => total + plan.points, 0);
  const rows = count('row_only');
  const credits = count('credit_and_row');
  const members = new Set(credits.map((plan) => plan.userId));
  console.log(`\n${label}`);
  console.log(`  already recorded         : ${alreadyRecorded}`);
  console.log(
    `  rows to write (no credit): ${rows.length} (${points(rows)} BNP)`,
  );
  console.log(
    `  credit + row (F-64)      : ${credits.length} (${points(credits)} BNP, ${members.size} member(s))`,
  );
  console.log(`  skipped, revoked pre-F-52: ${count('skip_reversed').length}`);
  console.log(`  needs review             : ${count('review').length}`);
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const connectionString =
    process.env.DIRECT_URL?.trim() || process.env.DATABASE_URL?.trim();
  if (!connectionString) {
    throw new Error('DIRECT_URL or DATABASE_URL is required');
  }

  const pool = new Pool({ connectionString });
  const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });
  const ranAt = new Date();

  try {
    console.log('F-63 / F-64 BNP reward-row backfill');
    console.log(`  mode           : ${options.apply ? 'APPLY' : 'DRY RUN'}`);
    console.log(`  part           : ${options.part}`);
    console.log(
      `  credited since : ${options.creditedSince.toISOString()} (F-52 live)`,
    );
    if (options.userIds.length > 0) {
      console.log(`  scoped to users: ${options.userIds.join(', ')}`);
    }
    BALANCE_WARNING.forEach((line) => console.log(line));

    const mining = await planMiningClaims(prisma, options.userIds);
    const quests = await planQuestRewards(
      prisma,
      options.userIds,
      options.creditedSince,
    );
    const all = [...mining.plans, ...quests.plans];

    console.log('\nPlan');
    all.forEach(printPlan);
    if (all.length === 0) console.log('  (nothing to do)');

    summarise('Mining claims', mining.plans, mining.alreadyRecorded);
    summarise('Quest rewards', quests.plans, quests.alreadyRecorded);

    if (!options.apply) {
      console.log(
        '\nDry run: nothing was written. Re-run with --apply to execute.',
      );
      BALANCE_WARNING.forEach((line) => console.log(line));
      return;
    }

    const runRows = options.part !== 'b';
    const runCredits = options.part !== 'a';
    let rowsWritten = 0;
    let credited = 0;
    for (const plan of all) {
      if (plan.action === 'row_only' && runRows) {
        if (await writeRowOnly(prisma, plan)) rowsWritten += 1;
      } else if (plan.action === 'credit_and_row' && runCredits) {
        if (await creditAndWriteRow(prisma, plan, ranAt)) credited += 1;
      }
    }

    console.log(`\nWrote ${rowsWritten} row(s) without a balance change.`);
    console.log(`Credited ${credited} quest reward(s) (balance + row).`);
    console.log('Re-run the dry run: it must report nothing to write.');
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
