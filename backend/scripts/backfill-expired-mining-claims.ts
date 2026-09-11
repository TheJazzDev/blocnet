/**
 * F-39 one-off backfill: make whole the accounts that a defect locked out of
 * mining.
 *
 * Background
 * ----------
 * Before F-39, a cycle whose 48h claim window elapsed never reached a terminal
 * state: `claim()` threw `claim_window_expired` without writing anything and
 * `start()` threw `claim_required` for the very same row, so the account could
 * neither claim nor start, forever. Those users did not forfeit their cycle by
 * choice — a bug took it — so the product owner decided their stranded points
 * are granted rather than forfeited. Going forward the 48h window stands and
 * elapsed cycles are forfeited by `MiningExpiryService`.
 *
 * Why a script and not a Prisma data migration
 * --------------------------------------------
 * A data migration fires automatically on every `prisma migrate deploy`, in
 * every environment, against data nobody looked at first. This grant moves real
 * balances, is environment-specific (prod has a different affected population),
 * and must be reviewed before it runs — so it is an explicit, dry-run-by-default
 * script instead. Running it is a deliberate act with a printed plan.
 *
 * Safety
 * ------
 * - Dry run unless `--apply` is passed.
 * - Idempotent: the payout is guarded on `claimedAt IS NULL`, so a second run
 *   finds no candidates and awards nothing.
 * - Points land through `applyClaimSettlement`, the exact same transaction the
 *   live `claim()` path uses (ledger row + profile balance + BNP tip account),
 *   never hand-written SQL.
 * - Every grant writes a `mining.claim.backfill` audit row (distinct from an
 *   ordinary `mining.claim`) and stamps `metadata.backfill = "F-39"` on the
 *   ledger row, so the one-off is traceable and reversible.
 *
 * Usage
 * -----
 *   cd backend
 *   bun run mining:backfill-expired-claims                  # dry run (default)
 *   bun run mining:backfill-expired-claims -- --apply       # execute
 *
 * Production
 * ----------
 *   1. Deploy the F-39 code + migration first (the terminal state must exist).
 *   2. Run the dry run against production and read the printed plan:
 *        DATABASE_URL=<prod> DIRECT_URL=<prod> bunx tsx scripts/backfill-expired-mining-claims.ts
 *   3. If the plan looks right, re-run with `--apply`.
 *   4. Re-run the dry run: it must report 0 candidates.
 *
 * Optional flags: `--user=<uuid[,uuid]>` to scope to specific accounts,
 * `--ended-before=<ISO>` to only settle cycles that ended before a cutoff.
 */
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { config as loadEnv } from 'dotenv';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { Pool } from 'pg';
import { LevelsService } from '../src/levels/levels.service';
import {
  applyClaimSettlement,
  resolveClaimPoints,
} from '../src/mining/mining-settlement';

loadEnv({ quiet: true });
loadEnv({ path: '.env.local', override: true, quiet: true });

const fallbackEnvPath = join(process.cwd(), 'backend/.env.local');
if (existsSync(fallbackEnvPath)) {
  loadEnv({ path: fallbackEnvPath, override: true, quiet: true });
}

const BACKFILL_TAG = 'F-39';
const BACKFILL_AUDIT_ACTION = 'mining.claim.backfill';

type CliOptions = {
  apply: boolean;
  userIds: string[];
  endedBefore: Date | null;
  claimWindowHours: number | null;
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

  const endedBeforeRaw = get('ended-before');
  const claimWindowRaw = get('claim-window-hours');

  return {
    apply: argv.includes('--apply'),
    userIds: (get('user') ?? '')
      .split(',')
      .map((value) => value.trim())
      .filter((value) => value.length > 0),
    endedBefore: endedBeforeRaw ? new Date(endedBeforeRaw) : null,
    claimWindowHours: claimWindowRaw ? Number(claimWindowRaw) : null,
  };
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

  try {
    const asOf = new Date();
    const configRow = await prisma.miningConfig.findUnique({
      where: { id: 'default' },
      select: { claimWindowHours: true },
    });
    const claimWindowHours =
      options.claimWindowHours ?? configRow?.claimWindowHours ?? 48;
    const windowCutoff = new Date(
      asOf.getTime() - claimWindowHours * 60 * 60 * 1000,
    );
    const endsBefore =
      options.endedBefore && options.endedBefore < windowCutoff
        ? options.endedBefore
        : windowCutoff;

    console.log('F-39 expired-claim backfill');
    console.log(`  mode              : ${options.apply ? 'APPLY' : 'DRY RUN'}`);
    console.log(`  asOf              : ${asOf.toISOString()}`);
    console.log(`  claimWindowHours  : ${claimWindowHours}`);
    console.log(`  settling cycles ending before: ${endsBefore.toISOString()}`);
    if (options.userIds.length > 0) {
      console.log(`  scoped to users   : ${options.userIds.join(', ')}`);
    }

    // Candidates are cycles that were never paid out and are past their claim
    // window. `expiredAt` is deliberately NOT filtered: once the F-39 fix is
    // live the reconciler forfeits these rows on the owner's next request, and
    // those accounts must still be made whole.
    const candidates = await prisma.miningSession.findMany({
      where: {
        claimedAt: null,
        endsAt: { lt: endsBefore },
        ...(options.userIds.length > 0
          ? { userId: { in: options.userIds } }
          : {}),
      },
      orderBy: [{ userId: 'asc' }, { startsAt: 'asc' }],
      select: {
        id: true,
        userId: true,
        startsAt: true,
        endsAt: true,
        expiredAt: true,
        basePointsPerCycle: true,
        effectivePointsPerCycle: true,
        boostBpsSnapshot: true,
        activeReferralsSnapshot: true,
      },
    });

    if (candidates.length === 0) {
      console.log('\nNo stranded cycles found — nothing to do.');
      return;
    }

    const levelsService = new LevelsService(prisma as never, {
      emitLevelUp: async () => {},
      emitLevelRecalculated: async () => {},
    } as never);

    const perUser = new Map<
      string,
      {
        username: string | null;
        email: string | null;
        before: bigint;
        granted: number;
        sessions: number;
      }
    >();

    for (const session of candidates) {
      const accrual = await prisma.miningHourlyCheckpoint.aggregate({
        where: { sessionId: session.id, claimedAt: null },
        _sum: { points: true },
        _count: { _all: true },
      });
      const claimPoints = resolveClaimPoints(accrual._sum.points, session);

      let entry = perUser.get(session.userId);
      if (!entry) {
        const profile = await prisma.profile.findUnique({
          where: { id: session.userId },
          select: {
            username: true,
            email: true,
            miningClaimedPoints: true,
          },
        });
        entry = {
          username: profile?.username ?? null,
          email: profile?.email ?? null,
          before: profile?.miningClaimedPoints ?? 0n,
          granted: 0,
          sessions: 0,
        };
        perUser.set(session.userId, entry);
      }

      console.log(
        `  ${options.apply ? 'grant' : 'would grant'} ${String(claimPoints).padStart(4)} pts  ` +
          `user=${session.userId} session=${session.id} ` +
          `ended=${session.endsAt.toISOString()} ` +
          `checkpoints=${accrual._count._all} ` +
          `alreadyForfeited=${session.expiredAt !== null}`,
      );

      if (!options.apply) {
        entry.granted += claimPoints;
        entry.sessions += 1;
        continue;
      }

      await prisma.$transaction((tx) =>
        applyClaimSettlement(tx, {
          userId: session.userId,
          session,
          claimedAt: asOf,
          claimPoints,
          checkpointCount: accrual._count._all,
          reclaimForfeited: true,
          extraLedgerMetadata: {
            backfill: BACKFILL_TAG,
            backfillReason: 'claim window deadlock (F-39)',
            backfillRanAt: asOf.toISOString(),
            forfeitedAt: session.expiredAt?.toISOString() ?? null,
          },
        }),
      );

      await prisma.auditLog.create({
        data: {
          actorId: session.userId,
          action: BACKFILL_AUDIT_ACTION,
          resourceType: 'mining_session',
          resourceId: session.id,
          metadata: {
            backfill: BACKFILL_TAG,
            reason:
              'Cycle stranded by the claim-window deadlock; granted, not forfeited.',
            points: claimPoints,
            hourlyCheckpointCount: accrual._count._all,
            startsAt: session.startsAt.toISOString(),
            endsAt: session.endsAt.toISOString(),
            claimWindowHours,
            grantedAt: asOf.toISOString(),
          },
        },
      });

      entry.granted += claimPoints;
      entry.sessions += 1;
    }

    if (options.apply) {
      for (const userId of perUser.keys()) {
        try {
          await levelsService.updateUserLevel(userId);
        } catch (error) {
          console.warn(
            `  ! level recalculation failed for ${userId}: ${
              error instanceof Error ? error.message : String(error)
            }`,
          );
        }
      }
    }

    console.log('\nPer-account totals');
    console.log(
      'userId                               username              sessions  before   granted  after',
    );

    let totalGranted = 0;
    for (const [userId, entry] of perUser) {
      const after = await prisma.profile.findUnique({
        where: { id: userId },
        select: { miningClaimedPoints: true },
      });
      totalGranted += entry.granted;
      console.log(
        `${userId}  ${(entry.username ?? '-').padEnd(20)}  ${String(entry.sessions).padStart(8)}  ` +
          `${String(entry.before).padStart(6)}  ${String(entry.granted).padStart(7)}  ` +
          `${String(after?.miningClaimedPoints ?? 0n).padStart(6)}`,
      );
    }

    console.log(
      `\n${options.apply ? 'Granted' : 'Would grant'} ${totalGranted} points across ` +
        `${perUser.size} account(s) / ${candidates.length} cycle(s).`,
    );

    if (!options.apply) {
      console.log('Dry run — re-run with --apply to execute.');
    }
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
