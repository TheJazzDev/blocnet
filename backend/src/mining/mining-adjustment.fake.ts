import { Prisma } from '@prisma/client';

/**
 * In-memory stand-in for the Prisma calls `MiningAdjustmentService` makes.
 * Writes are really applied and `$transaction` rolls them back on throw, so
 * the specs can assert that a rejected debit moved nothing.
 *
 * Excluded from the build via `tsconfig.build.json`.
 */

export type FakeProfile = {
  id: string;
  displayName: string | null;
  username: string | null;
  isDeactivated: boolean;
  miningClaimedPoints: bigint;
};

type Row = Record<string, any>;

type State = {
  profiles: FakeProfile[];
  tipAccounts: Row[];
  tipTransactions: Row[];
  ledger: Row[];
  auditLogs: Row[];
};

function uniqueViolation(): Error {
  return new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
    code: 'P2002',
    clientVersion: 'test',
  });
}

function pick(row: Row, select?: Record<string, boolean>): Row {
  if (!select) return { ...row };
  return Object.fromEntries(Object.keys(select).map((key) => [key, row[key]]));
}

function clone(state: State): State {
  return {
    profiles: state.profiles.map((row) => ({ ...row })),
    tipAccounts: state.tipAccounts.map((row) => ({ ...row })),
    tipTransactions: state.tipTransactions.map((row) => ({ ...row })),
    ledger: state.ledger.map((row) => ({ ...row })),
    auditLogs: state.auditLogs.map((row) => ({ ...row })),
  };
}

function applyBigIntOp(current: bigint, op: any): bigint {
  if (typeof op === 'bigint') return op;
  if (op?.increment !== undefined) return current + BigInt(op.increment);
  if (op?.decrement !== undefined) return current - BigInt(op.decrement);
  return current;
}

function matchesGte(value: bigint, filter: any): boolean {
  return filter?.gte === undefined || value >= BigInt(filter.gte);
}

export function createFakeAdjustmentDb(profiles: FakeProfile[]) {
  let state: State = {
    profiles,
    tipAccounts: [],
    tipTransactions: [],
    ledger: [],
    auditLogs: [],
  };
  let seq = 0;
  const nextId = (prefix: string) => `${prefix}-${++seq}`;
  const findProfile = (id: string) => state.profiles.find((p) => p.id === id);
  const findAccount = (where: Row) => {
    const key = where.accountType_ownerRef_currencyCode ?? where;
    return state.tipAccounts.find(
      (row) =>
        row.accountType === key.accountType &&
        row.ownerRef === key.ownerRef &&
        row.currencyCode === key.currencyCode,
    );
  };

  const client = {
    profile: {
      findUnique: jest.fn(async ({ where, select }: any) => {
        const row = findProfile(where.id);
        return row ? pick(row, select) : null;
      }),
      findUniqueOrThrow: jest.fn(async ({ where, select }: any) => {
        const row = findProfile(where.id);
        if (!row) throw new Error('Profile not found');
        return pick(row, select);
      }),
      findMany: jest.fn(async ({ where, select }: any) =>
        state.profiles
          .filter((row) => where.id.in.includes(row.id))
          .map((row) => pick(row, select)),
      ),
      update: jest.fn(async ({ where, data }: any) => {
        const row = findProfile(where.id)!;
        row.miningClaimedPoints = applyBigIntOp(
          row.miningClaimedPoints,
          data.miningClaimedPoints,
        );
        return { ...row };
      }),
      updateMany: jest.fn(async ({ where, data }: any) => {
        const row = findProfile(where.id);
        if (
          !row ||
          !matchesGte(row.miningClaimedPoints, where.miningClaimedPoints)
        ) {
          return { count: 0 };
        }
        row.miningClaimedPoints = applyBigIntOp(
          row.miningClaimedPoints,
          data.miningClaimedPoints,
        );
        return { count: 1 };
      }),
    },
    tipCurrency: {
      upsert: jest.fn(async () => ({})),
    },
    tipAccount: {
      upsert: jest.fn(async ({ where, create }: any) => {
        const existing = findAccount(where);
        if (existing) return { ...existing };
        const row = { id: nextId('acct'), ...create };
        state.tipAccounts.push(row);
        return { ...row };
      }),
      findUnique: jest.fn(async ({ where, select }: any) => {
        const row = findAccount(where);
        return row ? pick(row, select) : null;
      }),
      updateMany: jest.fn(async ({ where, data }: any) => {
        const row = findAccount(where);
        if (!row || !matchesGte(row.balanceAtomic, where.balanceAtomic)) {
          return { count: 0 };
        }
        row.balanceAtomic = applyBigIntOp(
          row.balanceAtomic,
          data.balanceAtomic,
        );
        return { count: 1 };
      }),
    },
    tipTransaction: {
      findUnique: jest.fn(async ({ where, select }: any) => {
        const row = state.tipTransactions.find(
          (tx) => tx.idempotencyKey === where.idempotencyKey,
        );
        return row ? pick(row, select) : null;
      }),
      create: jest.fn(async ({ data }: any) => {
        if (
          state.tipTransactions.some(
            (row) => row.idempotencyKey === data.idempotencyKey,
          )
        ) {
          throw uniqueViolation();
        }
        const row = { id: nextId('tip-tx'), ...data };
        state.tipTransactions.push(row);
        return { ...row };
      }),
    },
    miningPointLedger: {
      findUnique: jest.fn(async ({ where }: any) => {
        const row = state.ledger.find((entry) => entry.id === where.id);
        return row ? { ...row } : null;
      }),
      create: jest.fn(async ({ data }: any) => {
        const row = {
          id: data.id ?? nextId('ledger'),
          sessionId: null,
          createdAt: new Date(Date.UTC(2026, 8, 16, 0, 0, seq++)),
          ...data,
        };
        state.ledger.push(row);
        return { ...row };
      }),
      count: jest.fn(
        async ({ where }: any) =>
          state.ledger.filter(
            (row) => row.userId === where.userId && row.source === where.source,
          ).length,
      ),
      findMany: jest.fn(async ({ where, skip = 0, take }: any) =>
        state.ledger
          .filter(
            (row) => row.userId === where.userId && row.source === where.source,
          )
          .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
          .slice(skip, take === undefined ? undefined : skip + take)
          .map((row) => ({ ...row })),
      ),
    },
    auditLog: {
      create: jest.fn(async ({ data }: any) => {
        const row = { id: nextId('audit'), ...data };
        state.auditLogs.push(row);
        return row;
      }),
    },
    $transaction: jest.fn(async (callback: any) => {
      const snapshot = clone(state);
      try {
        return await callback(client);
      } catch (error) {
        state = snapshot;
        throw error;
      }
    }),
  };

  return {
    client,
    get state() {
      return state;
    },
    profile: (id: string) => findProfile(id)!,
    /** Simulates a member who tipped some BNP away (wallet < claimed). */
    setWalletAtomic(userId: string, balanceAtomic: bigint) {
      const row = state.tipAccounts.find((acct) => acct.ownerRef === userId);
      if (row) {
        row.balanceAtomic = balanceAtomic;
      } else {
        state.tipAccounts.push({
          id: nextId('acct'),
          accountType: 'user',
          ownerRef: userId,
          userId,
          currencyCode: 'BNP',
          balanceAtomic,
        });
      }
    },
    walletAtomic(userId: string): bigint | undefined {
      return state.tipAccounts.find((acct) => acct.ownerRef === userId)
        ?.balanceAtomic;
    },
  };
}
