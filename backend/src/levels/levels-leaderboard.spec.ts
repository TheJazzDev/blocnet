import { type INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { LevelsController } from './levels.controller';
import { LevelsService } from './levels.service';
import { LevelEventsService } from './level-events.service';
import { LevelIconStorageService } from './level-icon-storage.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';

// AuthGuard (pulled in by the controller) imports AuthService, which depends on
// the ESM-only `jose` package.
jest.mock('jose', () => ({
  createRemoteJWKSet: jest.fn(),
  jwtVerify: jest.fn(),
}));

type FakeLevel = {
  id: string;
  slug: string;
  name: string;
  description: string;
  iconUrl: string;
  level: number;
  requiredBnp: bigint;
  requiredComments: number;
  requiredDaysActive: number;
  requiredQuests: number;
  requiredUpdates: number;
  requiredProjects: number;
  color: string | null;
  isActive: boolean;
  sortOrder: number;
};

function makeLevel(level: number): FakeLevel {
  return {
    id: `level-${level}`,
    slug: `level-${level}`,
    name: `Level ${level}`,
    description: '',
    iconUrl: '',
    level,
    requiredBnp: BigInt(level * 1000),
    requiredComments: 0,
    requiredDaysActive: 0,
    requiredQuests: 0,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: null,
    isActive: true,
    sortOrder: level,
  };
}

type FakeRow = {
  userId: string;
  totalBnpEarned: bigint;
  totalComments: number;
  totalDaysActive: number;
  totalQuestsCompleted: number;
  achievedAt: Date;
  currentLevel: FakeLevel;
  user: {
    id: string;
    username: string;
    displayName: string;
    avatarUrl: string | null;
    isDeactivated: boolean;
  };
};

function makeRow(
  userId: string,
  level: number,
  bnp: number,
  isDeactivated = false,
): FakeRow {
  return {
    userId,
    totalBnpEarned: BigInt(bnp),
    totalComments: 0,
    totalDaysActive: 0,
    totalQuestsCompleted: 0,
    achievedAt: new Date('2026-01-01T00:00:00.000Z'),
    currentLevel: makeLevel(level),
    user: {
      id: userId,
      username: userId,
      displayName: userId,
      avatarUrl: null,
      isDeactivated,
    },
  };
}

/**
 * Minimal in-memory stand-in for `prisma.userLevelProgress`. It honours the
 * `where`, `orderBy`, `skip` and `take` the service actually sends, so the
 * ordering and pagination assertions below test the service's query rather
 * than a hand-written expectation of it.
 */
function makeFakePrisma(rows: FakeRow[]) {
  const findMany = jest.fn((args: any) => {
    let result = applyWhere(rows, args?.where);
    result = applyOrderBy(result, args?.orderBy ?? []);
    const skip = args?.skip ?? 0;
    const take = args?.take ?? result.length;
    return Promise.resolve(result.slice(skip, skip + take));
  });

  const count = jest.fn((args: any) =>
    Promise.resolve(applyWhere(rows, args?.where).length),
  );

  return {
    prisma: {
      userLevelProgress: { findMany, count },
    } as unknown as PrismaService,
    findMany,
    count,
  };
}

function applyWhere(rows: FakeRow[], where: any): FakeRow[] {
  const wantsActive = where?.user?.isDeactivated;
  if (wantsActive === undefined) return [...rows];
  return rows.filter((row) => row.user.isDeactivated === wantsActive);
}

function valueFor(row: FakeRow, clause: any): [unknown, 'asc' | 'desc'] {
  if ('currentLevel' in clause) {
    return [row.currentLevel.level, clause.currentLevel.level];
  }
  if ('totalBnpEarned' in clause) {
    return [row.totalBnpEarned, clause.totalBnpEarned];
  }
  if ('userId' in clause) {
    return [row.userId, clause.userId];
  }
  throw new Error(`Unsupported orderBy clause: ${JSON.stringify(clause)}`);
}

function applyOrderBy(rows: FakeRow[], orderBy: any[]): FakeRow[] {
  return [...rows].sort((a, b) => {
    for (const clause of orderBy) {
      const [left, direction] = valueFor(a, clause);
      const [right] = valueFor(b, clause);
      if (left === right) continue;
      const cmp = (left as any) < (right as any) ? -1 : 1;
      return direction === 'desc' ? -cmp : cmp;
    }
    return 0;
  });
}

function makeService(prisma: PrismaService): LevelsService {
  return new LevelsService(prisma, {
    emitLevelUp: jest.fn(),
  } as unknown as LevelEventsService);
}

describe('LevelsService.getLeaderboard', () => {
  it('clamps an oversized limit to the house maximum instead of scanning everything', async () => {
    const { prisma, findMany } = makeFakePrisma([makeRow('u1', 5, 500)]);

    const result = await makeService(prisma).getLeaderboard({ limit: 999999 });

    expect(findMany.mock.calls[0][0].take).toBe(100);
    expect(result.limit).toBe(100);
  });

  it('floors a zero or negative offset instead of letting it reach Prisma', async () => {
    const { prisma, findMany } = makeFakePrisma([makeRow('u1', 5, 500)]);

    const result = await makeService(prisma).getLeaderboard({ offset: -5 });

    expect(findMany.mock.calls[0][0].skip).toBe(0);
    expect(result.offset).toBe(0);
  });

  it('numbers ranks from the offset so page two continues page one', async () => {
    const rows = Array.from({ length: 7 }, (_, i) =>
      makeRow(`u${i}`, 10 - i, 1000 - i),
    );
    const { prisma } = makeFakePrisma(rows);
    const service = makeService(prisma);

    const pageOne = await service.getLeaderboard({ limit: 3, offset: 0 });
    const pageTwo = await service.getLeaderboard({ limit: 3, offset: 3 });

    expect(pageOne.data.map((e) => e.rank)).toEqual([1, 2, 3]);
    expect(pageTwo.data.map((e) => e.rank)).toEqual([4, 5, 6]);
    expect(pageTwo.data[0].user.id).toBe('u3');
    expect(pageTwo.total).toBe(7);
  });

  it('orders ties deterministically so repeated calls return the same ranks', async () => {
    // Every row ties on both level and BNP; only the user id can separate them.
    const tied = ['u3', 'u1', 'u4', 'u2'].map((id) => makeRow(id, 5, 500));
    const { prisma } = makeFakePrisma(tied);
    const service = makeService(prisma);

    const first = await service.getLeaderboard({ limit: 10 });
    // Shuffle the underlying rows, as an unordered table scan may between
    // two requests. With a deterministic final sort key the output must not move.
    tied.reverse();
    const second = await service.getLeaderboard({ limit: 10 });

    expect(first.data.map((e) => e.user.id)).toEqual(['u1', 'u2', 'u3', 'u4']);
    expect(second.data.map((e) => e.user.id)).toEqual(
      first.data.map((e) => e.user.id),
    );
  });

  it('keeps ties stable across a page boundary', async () => {
    const tied = ['u4', 'u2', 'u1', 'u3'].map((id) => makeRow(id, 5, 500));
    const { prisma } = makeFakePrisma(tied);
    const service = makeService(prisma);

    const pageOne = await service.getLeaderboard({ limit: 2, offset: 0 });
    const pageTwo = await service.getLeaderboard({ limit: 2, offset: 2 });

    const seen = [...pageOne.data, ...pageTwo.data].map((e) => e.user.id);
    expect(seen).toEqual(['u1', 'u2', 'u3', 'u4']);
    expect(new Set(seen).size).toBe(4);
  });

  it('excludes deactivated profiles from the public board and from the total', async () => {
    const { prisma } = makeFakePrisma([
      makeRow('active-1', 9, 900),
      makeRow('gone', 10, 1000, true),
      makeRow('active-2', 8, 800),
    ]);

    const result = await makeService(prisma).getLeaderboard({ limit: 10 });

    expect(result.data.map((e) => e.user.id)).toEqual(['active-1', 'active-2']);
    expect(result.total).toBe(2);
    expect(result.data[0].rank).toBe(1);
  });

  it('stays a single findMany plus a single count - no per-row follow-up query', async () => {
    const rows = Array.from({ length: 25 }, (_, i) =>
      makeRow(`u${i}`, 20 - (i % 20), 1000 - i),
    );
    const { prisma, findMany, count } = makeFakePrisma(rows);

    await makeService(prisma).getLeaderboard({ limit: 25 });

    expect(findMany).toHaveBeenCalledTimes(1);
    expect(count).toHaveBeenCalledTimes(1);
    expect(findMany.mock.calls[0][0].include).toEqual(
      expect.objectContaining({ currentLevel: true }),
    );
  });
});

describe('GET /levels/leaderboard', () => {
  let app: INestApplication;
  const levelsService = {
    getLeaderboard: jest.fn(),
  };

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [LevelsController],
      providers: [
        { provide: LevelsService, useValue: levelsService },
        { provide: LevelIconStorageService, useValue: {} },
      ],
    })
      // The leaderboard route is public; the guards belong to sibling routes on
      // the same controller and are stubbed so the module can be instantiated.
      .overrideGuard(AuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(RolesGuard)
      .useValue({ canActivate: () => true })
      .compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
      }),
    );
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    jest.clearAllMocks();
    levelsService.getLeaderboard.mockResolvedValue({
      total: 0,
      limit: 30,
      offset: 0,
      data: [],
    });
  });

  it.each(['abc', '1.5', '-5', '0'])(
    'rejects limit=%s with a 400 instead of letting Prisma throw',
    async (limit) => {
      await request(app.getHttpServer())
        .get('/levels/leaderboard')
        .query({ limit })
        .expect(400);

      expect(levelsService.getLeaderboard).not.toHaveBeenCalled();
    },
  );

  it.each(['abc', '-1', '2.5'])(
    'rejects offset=%s with a 400',
    async (offset) => {
      await request(app.getHttpServer())
        .get('/levels/leaderboard')
        .query({ offset })
        .expect(400);

      expect(levelsService.getLeaderboard).not.toHaveBeenCalled();
    },
  );

  it('passes validated numbers through to the service', async () => {
    await request(app.getHttpServer())
      .get('/levels/leaderboard')
      .query({ limit: '10', offset: '20' })
      .expect(200);

    expect(levelsService.getLeaderboard).toHaveBeenCalledWith({
      limit: 10,
      offset: 20,
    });
  });

  it('defaults both when nothing is supplied', async () => {
    await request(app.getHttpServer())
      .get('/levels/leaderboard')
      .expect(200);

    expect(levelsService.getLeaderboard).toHaveBeenCalledWith({
      limit: undefined,
      offset: undefined,
    });
  });

  it('returns the paginated envelope with a serialised level', async () => {
    levelsService.getLeaderboard.mockResolvedValue({
      total: 1,
      limit: 30,
      offset: 0,
      data: [
        {
          rank: 1,
          user: {
            id: 'u1',
            username: 'u1',
            displayName: 'U One',
            avatarUrl: null,
          },
          level: makeLevel(5),
          metrics: {
            totalBnpEarned: '500',
            totalComments: 1,
            totalDaysActive: 2,
            totalQuestsCompleted: 3,
          },
          achievedAt: new Date('2026-01-01T00:00:00.000Z'),
        },
      ],
    });

    const response = await request(app.getHttpServer())
      .get('/levels/leaderboard')
      .expect(200);

    expect(response.body).toEqual(
      expect.objectContaining({ total: 1, limit: 30, offset: 0 }),
    );
    expect(response.body.data[0].rank).toBe(1);
    // requiredBnp is a BigInt on the entity and must cross the wire as a string.
    expect(response.body.data[0].level.requiredBnp).toBe('5000');
  });
});
