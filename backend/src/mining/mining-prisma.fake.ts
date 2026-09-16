/**
 * Tiny in-memory stand-in for the Prisma calls the mining services make.
 *
 * Mining settlement is balance-moving code where the interesting bugs live in
 * the *sequence* of reads and writes (F-39 was exactly that), so the specs run
 * against a store that actually applies the writes rather than a pile of
 * `mockResolvedValueOnce` stubs that cannot catch a double-award.
 *
 * Excluded from the build via `tsconfig.build.json`.
 */

export type FakeSessionRow = {
  id: string;
  userId: string;
  startsAt: Date;
  endsAt: Date;
  claimedAt: Date | null;
  expiredAt: Date | null;
  basePointsPerCycle: number;
  effectivePointsPerCycle: number;
  boostBpsSnapshot: number;
  activeReferralsSnapshot: number;
};

export type FakeCheckpointRow = {
  id: string;
  userId: string;
  sessionId: string;
  hourIndex: number;
  hourStartAt: Date;
  hourEndAt: Date;
  points: number;
  activeReferralsSnapshot: number;
  boostBpsSnapshot: number;
  claimedAt: Date | null;
  expiredAt: Date | null;
};

type NullableFilter = null | { not: null } | undefined;

function matchesNullable(value: Date | null, filter: NullableFilter): boolean {
  if (filter === undefined) return true;
  if (filter === null) return value === null;
  if (typeof filter === 'object' && 'not' in filter && filter.not === null) {
    return value !== null;
  }
  return true;
}

function matchesDateRange(
  value: Date,
  filter: { lt?: Date; lte?: Date; gt?: Date; gte?: Date } | undefined,
): boolean {
  if (!filter) return true;
  if (filter.lt && !(value.getTime() < filter.lt.getTime())) return false;
  if (filter.lte && !(value.getTime() <= filter.lte.getTime())) return false;
  if (filter.gt && !(value.getTime() > filter.gt.getTime())) return false;
  if (filter.gte && !(value.getTime() >= filter.gte.getTime())) return false;
  return true;
}

function sortRows<T extends Record<string, unknown>>(
  rows: T[],
  orderBy: unknown,
): T[] {
  const clauses = (Array.isArray(orderBy) ? orderBy : [orderBy]).filter(
    Boolean,
  ) as Array<Record<string, 'asc' | 'desc'>>;

  if (clauses.length === 0) return rows;

  return [...rows].sort((left, right) => {
    for (const clause of clauses) {
      const [field, direction] = Object.entries(clause)[0] ?? [];
      if (!field) continue;
      const leftValue = left[field];
      const rightValue = right[field];
      const leftMs = leftValue instanceof Date ? leftValue.getTime() : 0;
      const rightMs = rightValue instanceof Date ? rightValue.getTime() : 0;
      if (leftMs === rightMs) continue;
      return direction === 'desc' ? rightMs - leftMs : leftMs - rightMs;
    }
    return 0;
  });
}

export type FakeMiningDbOptions = {
  userId?: string;
  sessions?: FakeSessionRow[];
  checkpoints?: FakeCheckpointRow[];
  miningClaimedPoints?: bigint;
};

/**
 * Returns an object shaped like the slice of `PrismaService` the mining
 * services touch, plus the underlying rows so specs can assert on final state.
 */
export function createFakeMiningDb(options: FakeMiningDbOptions = {}) {
  const userId = options.userId ?? 'user-1';
  const sessions: FakeSessionRow[] = options.sessions ?? [];
  const checkpoints: FakeCheckpointRow[] = options.checkpoints ?? [];
  const profile = {
    id: userId,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    referralCode: 'REF123',
    referredById: null as string | null,
    miningClaimedPoints: options.miningClaimedPoints ?? 0n,
    currentLevelId: null as string | null,
  };
  const ledger: Array<Record<string, unknown>> = [];
  const tipAccounts: Array<Record<string, unknown>> = [];
  const tipTransactions: Array<Record<string, any>> = [];
  let sessionSeq = sessions.length;
  let checkpointSeq = checkpoints.length;

  /**
   * Ordered trace of transaction boundaries, advisory locks and session
   * reads/creates, tagged with the transaction they ran in (`null` = outside
   * any transaction), so specs can assert *where* a check-then-create ran.
   */
  const events: Array<{ op: string; tx: number | null; detail?: unknown }> = [];
  let txSeq = 0;

  /**
   * `pg_advisory_xact_lock` stand-in: a per-key FIFO mutex held until the
   * owning transaction callback settles, exactly like Postgres releases it at
   * commit/rollback.
   */
  const advisoryLocks = new Map<string, Promise<void>>();
  async function acquireAdvisoryLock(key: string): Promise<() => void> {
    const previous = advisoryLocks.get(key) ?? Promise.resolve();
    let release!: () => void;
    const current = new Promise<void>((resolve) => {
      release = resolve;
    });
    const chained = previous.then(() => current);
    advisoryLocks.set(key, chained);
    await previous;
    return () => {
      release();
      if (advisoryLocks.get(key) === chained) advisoryLocks.delete(key);
    };
  }

  const selectSessions = (where: any = {}) =>
    sessions.filter(
      (row) =>
        (where.id === undefined || row.id === where.id) &&
        (where.userId === undefined || row.userId === where.userId) &&
        matchesNullable(row.claimedAt, where.claimedAt) &&
        matchesNullable(row.expiredAt, where.expiredAt) &&
        matchesDateRange(row.endsAt, where.endsAt) &&
        matchesDateRange(row.startsAt, where.startsAt),
    );

  const selectCheckpoints = (where: any = {}) =>
    checkpoints.filter(
      (row) =>
        (where.userId === undefined || row.userId === where.userId) &&
        (where.sessionId === undefined || row.sessionId === where.sessionId) &&
        matchesNullable(row.claimedAt, where.claimedAt) &&
        matchesNullable(row.expiredAt, where.expiredAt) &&
        matchesDateRange(row.hourEndAt, where.hourEndAt),
    );

  const checkpointExists = (data: any) =>
    checkpoints.some(
      (row) =>
        row.sessionId === data.sessionId && row.hourIndex === data.hourIndex,
    );

  const insertCheckpoint = (data: any): FakeCheckpointRow => {
    checkpointSeq += 1;
    const row: FakeCheckpointRow = {
      id: `checkpoint-${checkpointSeq}`,
      userId: data.userId,
      sessionId: data.sessionId,
      hourIndex: data.hourIndex,
      hourStartAt: data.hourStartAt,
      hourEndAt: data.hourEndAt,
      points: data.points,
      activeReferralsSnapshot: data.activeReferralsSnapshot,
      boostBpsSnapshot: data.boostBpsSnapshot,
      claimedAt: null,
      expiredAt: null,
    };
    checkpoints.push(row);
    return row;
  };

  const client = {
    profile: {
      findUnique: jest.fn(async ({ where }: any) =>
        where?.id === userId ? { ...profile } : null,
      ),
      update: jest.fn(async ({ data }: any) => {
        if (data?.miningClaimedPoints?.increment !== undefined) {
          profile.miningClaimedPoints +=
            BigInt(data.miningClaimedPoints.increment);
        }
        return { ...profile };
      }),
      count: jest.fn(async () => 0),
    },
    miningSession: {
      findMany: jest.fn(async ({ where, orderBy, take }: any = {}) => {
        const rows = sortRows(selectSessions(where), orderBy);
        return (take ? rows.slice(0, take) : rows).map((row) => ({ ...row }));
      }),
      findFirst: jest.fn(async ({ where, orderBy }: any = {}) => {
        const rows = sortRows(selectSessions(where), orderBy);
        return rows.length > 0 ? { ...rows[0] } : null;
      }),
      create: jest.fn(async ({ data }: any) => {
        sessionSeq += 1;
        const row: FakeSessionRow = {
          id: `session-new-${sessionSeq}`,
          userId: data.userId,
          startsAt: data.startsAt,
          endsAt: data.endsAt,
          claimedAt: null,
          expiredAt: null,
          basePointsPerCycle: data.basePointsPerCycle,
          effectivePointsPerCycle: data.effectivePointsPerCycle,
          boostBpsSnapshot: data.boostBpsSnapshot,
          activeReferralsSnapshot: data.activeReferralsSnapshot,
        };
        sessions.push(row);
        return { ...row };
      }),
      updateMany: jest.fn(async ({ where, data }: any) => {
        const rows = selectSessions(where);
        for (const row of rows) {
          if (data.claimedAt !== undefined) row.claimedAt = data.claimedAt;
          if (data.expiredAt !== undefined) row.expiredAt = data.expiredAt;
        }
        return { count: rows.length };
      }),
    },
    miningHourlyCheckpoint: {
      findMany: jest.fn(async ({ where, orderBy, take }: any = {}) => {
        const rows = sortRows(selectCheckpoints(where), orderBy);
        return (take ? rows.slice(0, take) : rows).map((row) => ({ ...row }));
      }),
      create: jest.fn(async ({ data }: any) => {
        if (checkpointExists(data)) {
          // Mirrors @@unique([sessionId, hourIndex]).
          throw Object.assign(new Error('Unique constraint failed'), {
            code: 'P2002',
          });
        }
        return { ...insertCheckpoint(data) };
      }),
      createMany: jest.fn(async ({ data, skipDuplicates }: any) => {
        let count = 0;
        for (const item of data) {
          if (checkpointExists(item)) {
            if (skipDuplicates) continue;
            throw Object.assign(new Error('Unique constraint failed'), {
              code: 'P2002',
            });
          }
          insertCheckpoint(item);
          count += 1;
        }
        return { count };
      }),
      aggregate: jest.fn(async ({ where }: any = {}) => {
        const rows = selectCheckpoints(where);
        return {
          _sum: {
            points: rows.reduce((total, row) => total + row.points, 0),
          },
          _max: {
            hourIndex: rows.reduce<number | null>(
              (max, row) => (max === null || row.hourIndex > max ? row.hourIndex : max),
              null,
            ),
          },
          _count: { _all: rows.length },
        };
      }),
      count: jest.fn(async ({ where }: any = {}) => selectCheckpoints(where).length),
      updateMany: jest.fn(async ({ where, data }: any) => {
        const rows = selectCheckpoints(where);
        for (const row of rows) {
          if (data.claimedAt !== undefined) row.claimedAt = data.claimedAt;
          if (data.expiredAt !== undefined) row.expiredAt = data.expiredAt;
        }
        return { count: rows.length };
      }),
    },
    miningPointLedger: {
      create: jest.fn(async ({ data }: any) => {
        ledger.push(data);
        return { id: `ledger-${ledger.length}`, ...data };
      }),
      findMany: jest.fn(async () => [...ledger]),
    },
    tipCurrency: {
      upsert: jest.fn(async () => ({})),
    },
    tipAccount: {
      upsert: jest.fn(async ({ create, update }: any) => {
        tipAccounts.push(update ?? create);
        return { id: `tip-account-${userId}` };
      }),
    },
    tipTransaction: {
      findUnique: jest.fn(async ({ where }: any) => {
        const row = tipTransactions.find(
          (item) => item.idempotencyKey === where?.idempotencyKey,
        );
        return row ? { ...row } : null;
      }),
      create: jest.fn(async ({ data }: any) => {
        if (
          tipTransactions.some(
            (item) => item.idempotencyKey === data.idempotencyKey,
          )
        ) {
          // Mirrors TipTransaction.idempotencyKey @unique.
          throw Object.assign(new Error('Unique constraint failed'), {
            code: 'P2002',
          });
        }
        const row = { id: `tip-tx-${tipTransactions.length + 1}`, ...data };
        tipTransactions.push(row);
        return { ...row };
      }),
    },
    miningConfig: {
      upsert: jest.fn(async () => ({})),
    },
    $executeRaw: jest.fn(async (strings: TemplateStringsArray, ...values: unknown[]) => {
      // Outside a transaction an xact lock would release immediately.
      events.push({ op: 'executeRaw', tx: null, detail: { sql: strings.join('?'), values } });
      return 1;
    }),
    $transaction: jest.fn(async (callback: any) => {
      txSeq += 1;
      const txId = txSeq;
      const held: Array<() => void> = [];
      const traced = (op: string, fn: (...args: any[]) => any) =>
        jest.fn(async (...args: any[]) => {
          events.push({ op, tx: txId, detail: args[0] });
          return fn(...args);
        });
      const tx = {
        ...client,
        miningSession: {
          ...client.miningSession,
          findMany: traced('miningSession.findMany', rawSessionFindMany),
          create: traced('miningSession.create', rawSessionCreate),
        },
        $executeRaw: jest.fn(async (strings: TemplateStringsArray, ...values: unknown[]) => {
          const sql = strings.join('?');
          events.push({ op: 'executeRaw', tx: txId, detail: { sql, values } });
          if (sql.includes('pg_advisory_xact_lock')) {
            held.push(await acquireAdvisoryLock(String(values[0])));
            events.push({ op: 'lock.acquired', tx: txId, detail: values[0] });
          }
          return 1;
        }),
      };
      events.push({ op: 'tx.begin', tx: txId });
      try {
        return await callback(tx);
      } finally {
        events.push({ op: 'tx.end', tx: txId });
        held.forEach((release) => release());
      }
    }),
  };

  // Calls made outside a transaction are traced with tx: null.
  const rawSessionFindMany = client.miningSession.findMany;
  const rawSessionCreate = client.miningSession.create;
  client.miningSession.findMany = jest.fn(async (args: any) => {
    events.push({ op: 'miningSession.findMany', tx: null, detail: args });
    return rawSessionFindMany(args);
  }) as typeof rawSessionFindMany;
  client.miningSession.create = jest.fn(async (args: any) => {
    events.push({ op: 'miningSession.create', tx: null, detail: args });
    return rawSessionCreate(args);
  }) as typeof rawSessionCreate;

  return {
    client,
    sessions,
    checkpoints,
    ledger,
    tipAccounts,
    tipTransactions,
    profile,
    events,
  };
}
