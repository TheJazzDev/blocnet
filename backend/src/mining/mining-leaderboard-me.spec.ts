import { MiningCalculatorService } from './mining-calculator.service';
import { MiningLeaderboardService } from './mining-leaderboard.service';

/**
 * In-memory profile table that evaluates the subset of Prisma where/orderBy
 * the leaderboard uses, so `me.rank` is checked against the rows the board
 * really produces rather than against hand-picked mock values.
 */
type FakeProfile = {
  id: string;
  username: string;
  displayName: string;
  createdAt: Date;
  miningClaimedPoints: bigint;
  isDeactivated?: boolean;
  unclaimedPoints?: number;
  running?: boolean;
};

function matches(p: FakeProfile, where: any): boolean {
  if (!where) return true;
  for (const [key, cond] of Object.entries<any>(where)) {
    switch (key) {
      case 'AND':
        if (!cond.every((w: any) => matches(p, w))) return false;
        break;
      case 'OR':
        if (!cond.some((w: any) => matches(p, w))) return false;
        break;
      case 'isDeactivated':
        if ((p.isDeactivated ?? false) !== cond) return false;
        break;
      case 'id':
        if (p.id !== cond) return false;
        break;
      case 'miningClaimedPoints':
        if (typeof cond === 'bigint') {
          if (p.miningClaimedPoints !== cond) return false;
        } else if (!(p.miningClaimedPoints > cond.gt)) return false;
        break;
      case 'createdAt':
        if (!(p.createdAt.getTime() < cond.lt.getTime())) return false;
        break;
      case 'miningHourlyCheckpoints':
        if (!((p.unclaimedPoints ?? 0) > 0)) return false;
        break;
      case 'displayName':
      case 'username': {
        const value = String(p[key]).toLowerCase();
        if (!value.includes(String(cond.contains).toLowerCase())) return false;
        break;
      }
      default:
        throw new Error(`fake prisma: unsupported where key ${key}`);
    }
  }
  return true;
}

function toRecord(p: FakeProfile, now: number) {
  const hour = 60 * 60 * 1000;
  return {
    id: p.id,
    email: `${p.id}@example.com`,
    username: p.username,
    displayName: p.displayName,
    avatarUrl: null,
    createdAt: p.createdAt,
    miningClaimedPoints: p.miningClaimedPoints,
    primaryBadge: null,
    currentLevel: null,
    miningSessions: p.running
      ? [
          {
            id: `session-${p.id}`,
            startsAt: new Date(now - hour),
            endsAt: new Date(now + 23 * hour),
            boostBpsSnapshot: 0,
            activeReferralsSnapshot: 0,
          },
        ]
      : [],
  };
}

function makeFakePrisma(table: FakeProfile[]) {
  const now = Date.now();
  const sorted = () =>
    [...table].sort((a, b) =>
      a.miningClaimedPoints === b.miningClaimedPoints
        ? a.createdAt.getTime() - b.createdAt.getTime()
        : a.miningClaimedPoints > b.miningClaimedPoints
          ? -1
          : 1,
    );
  return {
    profile: {
      findMany: jest.fn(async (args: any) =>
        sorted()
          .filter((p) => matches(p, args.where))
          .slice(args.skip, args.skip + args.take)
          .map((p) => toRecord(p, now)),
      ),
      findFirst: jest.fn(async (args: any) => {
        const found = table.find((p) => matches(p, args.where));
        return found ? toRecord(found, now) : null;
      }),
      count: jest.fn(
        async (args: any) => table.filter((p) => matches(p, args.where)).length,
      ),
    },
    miningHourlyCheckpoint: {
      groupBy: jest.fn(async (args: any) =>
        table
          .filter((p) => args.where.userId.in.includes(p.id))
          .map((p) => ({
            userId: p.id,
            _sum: { points: p.unclaimedPoints ?? 0 },
          })),
      ),
    },
  };
}

const day = (n: number) => new Date(Date.UTC(2026, 0, n));

// Board order: alice(900), bob(500, older), carol(500, newer), dave(300),
// erin(0 claimed, 40 unclaimed). frank has nothing; gina is deactivated.
const TABLE: FakeProfile[] = [
  {
    id: 'carol',
    username: 'carol',
    displayName: 'Carol',
    createdAt: day(5),
    miningClaimedPoints: 500n,
  },
  {
    id: 'alice',
    username: 'alice',
    displayName: 'Alice',
    createdAt: day(9),
    miningClaimedPoints: 900n,
  },
  {
    id: 'dave',
    username: 'dave',
    displayName: 'Dave',
    createdAt: day(1),
    miningClaimedPoints: 300n,
    running: true,
  },
  {
    id: 'bob',
    username: 'bob',
    displayName: 'Bob',
    createdAt: day(2),
    miningClaimedPoints: 500n,
  },
  {
    id: 'erin',
    username: 'erin',
    displayName: 'Erin',
    createdAt: day(3),
    miningClaimedPoints: 0n,
    unclaimedPoints: 40,
  },
  {
    id: 'frank',
    username: 'frank',
    displayName: 'Frank',
    createdAt: day(4),
    miningClaimedPoints: 0n,
  },
  {
    id: 'gina',
    username: 'gina',
    displayName: 'Gina',
    createdAt: day(1),
    miningClaimedPoints: 5000n,
    isDeactivated: true,
  },
];

describe('MiningLeaderboardService me', () => {
  const miningCalculator = {
    computeProgressPct: jest.fn().mockReturnValue(4),
  } as unknown as MiningCalculatorService;
  const miningConfigService = {
    getEffectiveConfig: jest.fn().mockResolvedValue({ claimWindowHours: 48 }),
  };

  let prisma: ReturnType<typeof makeFakePrisma>;
  let service: MiningLeaderboardService;

  beforeEach(() => {
    prisma = makeFakePrisma(TABLE);
    service = new MiningLeaderboardService(
      prisma as any,
      miningCalculator,
      miningConfigService as any,
    );
  });

  it('pins the ranked caller with the same fields their row carries', async () => {
    const result = await service.getLeaderboard({ viewerId: 'alice' });

    expect(result.data.map((r) => r.userId)).toEqual([
      'alice',
      'bob',
      'carol',
      'dave',
      'erin',
    ]);
    expect(result.me).toEqual({ ...result.data[0], isMiningNow: false });
    expect(result.me).toMatchObject({
      rank: 1,
      userId: 'alice',
      displayName: 'Alice',
      claimedTotalPoints: '900',
      currentLevel: null,
      sessionStatus: 'idle',
    });
    // Two bounded queries for `me`, never a board scan.
    expect(prisma.profile.findFirst).toHaveBeenCalledTimes(1);
    expect(prisma.profile.count).toHaveBeenCalledTimes(2);
  });

  it('flags a running cycle as isMiningNow', async () => {
    const result = await service.getLeaderboard({ viewerId: 'dave' });
    expect(result.me).toMatchObject({
      rank: 4,
      sessionStatus: 'running',
      isMiningNow: true,
    });
  });

  it.each(['frank', 'gina', 'nobody'])(
    'returns me: null when %s is not ranked',
    async (viewerId) => {
      const result = await service.getLeaderboard({ viewerId });
      expect(result.me).toBeNull();
      expect(prisma.profile.count).toHaveBeenCalledTimes(1);
    },
  );

  it('ranks a member with only unclaimed points', async () => {
    const result = await service.getLeaderboard({ viewerId: 'erin' });
    expect(result.me).toMatchObject({
      rank: 5,
      maturedUnclaimedPoints: 40,
      lifetimeEarnedPoints: '40',
    });
  });

  it('breaks a tie on points by createdAt, matching the rows', async () => {
    const board = await service.getLeaderboard({ limit: 100 });
    const bob = await service.getLeaderboard({ viewerId: 'bob' });
    const carol = await service.getLeaderboard({ viewerId: 'carol' });

    expect(bob.me?.rank).toBe(2);
    expect(carol.me?.rank).toBe(3);
    expect(board.data.find((r) => r.userId === 'bob')?.rank).toBe(2);
    expect(board.data.find((r) => r.userId === 'carol')?.rank).toBe(3);
  });

  it('agrees with the row rank when the caller is on a later page', async () => {
    for (const viewerId of ['alice', 'bob', 'carol', 'dave', 'erin']) {
      for (const offset of [0, 2, 4]) {
        const result = await service.getLeaderboard({
          viewerId,
          limit: 2,
          offset,
        });
        const row = result.data.find((r) => r.userId === viewerId);
        if (row) {
          expect(result.me?.rank).toBe(row.rank);
        }
      }
    }

    const page3 = await service.getLeaderboard({
      viewerId: 'dave',
      limit: 2,
      offset: 2,
    });
    expect(page3.data.map((r) => r.userId)).toEqual(['carol', 'dave']);
    expect(page3.me?.rank).toBe(page3.data[1].rank);

    const firstPage = await service.getLeaderboard({
      viewerId: 'erin',
      limit: 2,
    });
    expect(firstPage.data.map((r) => r.userId)).not.toContain('erin');
    expect(firstPage.me).toMatchObject({ rank: 5, maturedUnclaimedPoints: 40 });
  });

  it('ranks the caller on the whole board, ignoring the search filter', async () => {
    const result = await service.getLeaderboard({
      viewerId: 'carol',
      q: 'car',
    });
    expect(result.data).toHaveLength(1);
    expect(result.data[0].rank).toBe(1);
    expect(result.me?.rank).toBe(3);
  });

  it('omits me when no viewer is given (admin board)', async () => {
    const result = await service.getLeaderboard({ includePrivateFields: true });
    expect(result).not.toHaveProperty('me');
    expect(prisma.profile.findFirst).not.toHaveBeenCalled();
  });
});
