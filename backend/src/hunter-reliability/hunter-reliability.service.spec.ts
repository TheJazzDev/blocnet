import { NotFoundException } from '@nestjs/common';
import { HunterReliabilityService } from './hunter-reliability.service';
import { ReliabilityLoader } from './reliability.loader';

const NOW = new Date('2026-09-16T12:00:00.000Z');
const DAY = 24 * 60 * 60 * 1000;
const daysAgo = (n: number) => new Date(NOW.getTime() - n * DAY);

class FixedClockService extends HunterReliabilityService {
  protected now() {
    return NOW;
  }
}

const HUNTER = '11111111-1111-4111-8111-111111111111';
const OTHER = '22222222-2222-4222-8222-222222222222';
const ADMIN = '33333333-3333-4333-8333-333333333333';

function profile(id: string, username: string) {
  return {
    id,
    username,
    displayName: username.toUpperCase(),
    avatarUrl: null,
    currentLevel: null,
  };
}

function project(
  id: string,
  opts: { listed: number; hunters?: string[]; owner?: string; name?: string },
) {
  return {
    id,
    name: opts.name ?? id,
    createdAt: daysAgo(opts.listed),
    ownerAdminId: opts.owner ?? ADMIN,
    primaryTag: { name: 'DeFi' },
    hunters: (opts.hunters ?? []).map((hunterId) => ({ hunterId })),
  };
}

/**
 * Mock Prisma. `update.groupBy` answers both the "newest update" and the
 * "next deadline" reads, told apart by which aggregate was asked for.
 */
function createService(data: {
  profiles: ReturnType<typeof profile>[];
  projects: ReturnType<typeof project>[];
  lastUpdates?: Record<string, Date>;
  windowUpdates?: { projectId: string; createdAt: Date }[];
  asks?: { projectId: string; createdAt: Date }[];
  openReports?: Record<string, number>;
  followers?: Record<string, number>;
  deadlines?: Record<string, Date>;
  lastUpdateRows?: {
    id: string;
    projectId: string;
    title: string;
    createdAt: Date;
  }[];
  tips?: Record<string, bigint>;
}) {
  const prisma = {
    profile: { findMany: jest.fn().mockResolvedValue(data.profiles) },
    project: { findMany: jest.fn().mockResolvedValue(data.projects) },
    update: {
      groupBy: jest.fn().mockImplementation((args: any) => {
        if (args._min) {
          return Promise.resolve(
            Object.entries(data.deadlines ?? {}).map(([projectId, d]) => ({
              projectId,
              _min: { deadlineAt: d },
            })),
          );
        }
        return Promise.resolve(
          Object.entries(data.lastUpdates ?? {}).map(([projectId, d]) => ({
            projectId,
            _max: { createdAt: d },
          })),
        );
      }),
      findMany: jest
        .fn()
        .mockImplementation((args: any) =>
          Promise.resolve(
            args.where.OR
              ? (data.lastUpdateRows ?? [])
              : (data.windowUpdates ?? []),
          ),
        ),
    },
    projectUpdateRequest: {
      findMany: jest.fn().mockResolvedValue(data.asks ?? []),
    },
    projectInactivityReport: {
      groupBy: jest.fn().mockResolvedValue(
        Object.entries(data.openReports ?? {}).map(([projectId, n]) => ({
          projectId,
          _count: { _all: n },
        })),
      ),
    },
    projectFollow: {
      groupBy: jest.fn().mockResolvedValue(
        Object.entries(data.followers ?? {}).map(([projectId, n]) => ({
          projectId,
          _count: { _all: n },
        })),
      ),
    },
    tipCurrency: {
      findFirst: jest.fn().mockResolvedValue({ code: 'BNP', decimals: 2 }),
    },
    tipTransaction: {
      groupBy: jest.fn().mockResolvedValue(
        Object.entries(data.tips ?? {}).map(([recipientUserId, sum]) => ({
          recipientUserId,
          _sum: { amountAtomic: sum },
        })),
      ),
    },
  } as any;

  const service = new FixedClockService(new ReliabilityLoader(prisma));
  return { service, prisma };
}

function totalQueries(prisma: any): number {
  let total = 0;
  for (const model of Object.values(prisma)) {
    for (const fn of Object.values(model as Record<string, jest.Mock>)) {
      total += fn.mock.calls.length;
    }
  }
  return total;
}

describe('HunterReliabilityService', () => {
  describe('getReliability', () => {
    it('404s for an unknown profile', async () => {
      const { service } = createService({ profiles: [], projects: [] });
      await expect(service.getReliability(HUNTER)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('returns a new hunter with null scores when they own nothing', async () => {
      const { service, prisma } = createService({
        profiles: [profile(HUNTER, 'ada')],
        projects: [],
      });
      const result = await service.getReliability(HUNTER);
      expect(result).toMatchObject({
        profileId: HUNTER,
        username: 'ada',
        standing: 'new',
        coverage: null,
        cadenceDays: null,
        response: null,
        gemsOwned: 0,
        tipsReceivedTotal: '0',
        tipsCurrencyCode: 'BNP',
      });
      // No gem-scoped reads when there are no gems.
      expect(prisma.projectUpdateRequest.findMany).not.toHaveBeenCalled();
    });

    it('counts only gems the hunter owns under the ownership rule', async () => {
      const { service, prisma } = createService({
        profiles: [profile(HUNTER, 'ada')],
        projects: [
          project('mine', { listed: 60, hunters: [HUNTER] }),
          project('shared', { listed: 60, hunters: [OTHER, HUNTER] }),
          // Returned by the OR filter's admin branch only if HUNTER were the
          // admin; here the admin is someone else, so it must be dropped.
          project('theirs', { listed: 60, hunters: [OTHER] }),
          project('unassigned-mine', { listed: 60, owner: HUNTER }),
        ],
        lastUpdates: {
          mine: daysAgo(1),
          shared: daysAgo(30),
          theirs: daysAgo(1),
        },
        windowUpdates: [
          { projectId: 'mine', createdAt: daysAgo(21) },
          { projectId: 'mine', createdAt: daysAgo(11) },
          { projectId: 'mine', createdAt: daysAgo(1) },
          { projectId: 'theirs', createdAt: daysAgo(1) },
        ],
        asks: [
          { projectId: 'mine', createdAt: daysAgo(3) },
          { projectId: 'shared', createdAt: daysAgo(20) },
          { projectId: 'theirs', createdAt: daysAgo(2) },
        ],
        openReports: { shared: 2, theirs: 5 },
        followers: { mine: 10, shared: 5, theirs: 100 },
        tips: { [HUNTER]: 123456789012345678901234567890n },
      });

      const result = await service.getReliability(HUNTER);

      expect(result).toMatchObject({
        gemsOwned: 3,
        // mine current; shared quiet; unassigned-mine never updated, 60d → quiet.
        coverage: 0.333,
        standing: 'quiet',
        cadenceDays: 10,
        // mine's ask is still open but answered by the update a day ago;
        // shared's ask 20 days ago was never answered.
        response: 0.5,
        updates30d: 3,
        followersTotal: 15,
        membersWaiting: 1,
        openReports: 2,
        tipsReceivedTotal: '123456789012345678901234567890',
      });

      // BNP transfers share the tip ledger; only real tips count.
      expect(prisma.tipTransaction.groupBy.mock.calls[0][0].where).toEqual(
        expect.objectContaining({ type: 'tip' }),
      );

      const where = prisma.project.findMany.mock.calls[0][0].where;
      expect(where.status).toBe('active');
      expect(where.OR).toEqual([
        { hunters: { some: { hunterId: { in: [HUNTER] } } } },
        { hunters: { none: {} }, ownerAdminId: { in: [HUNTER] } },
      ]);
    });
  });

  describe('getLeaderboard', () => {
    function leaderboardService() {
      return createService({
        profiles: [
          profile(HUNTER, 'ada'),
          profile(OTHER, 'bob'),
          profile(ADMIN, 'root'),
        ],
        projects: [
          project('a1', { listed: 60, hunters: [HUNTER] }),
          project('b1', { listed: 60, hunters: [OTHER] }),
          project('b2', { listed: 60, hunters: [OTHER] }),
          project('r1', { listed: 3, owner: ADMIN }),
        ],
        lastUpdates: { a1: daysAgo(1), b1: daysAgo(2), b2: daysAgo(40) },
      });
    }

    it('ranks by standing and pages with a cursor', async () => {
      const { service, prisma } = leaderboardService();

      const first = await service.getLeaderboard({ limit: 2 });
      expect(first.items.map((i) => [i.username, i.standing, i.rank])).toEqual([
        ['ada', 'reliable', 1],
        ['bob', 'slipping', 2],
      ]);
      expect(first.nextCursor).toBe('2');

      const second = await service.getLeaderboard({ limit: 2, cursor: '2' });
      expect(second.items.map((i) => [i.username, i.standing, i.rank])).toEqual(
        [['root', 'new', 3]],
      );
      expect(second.nextCursor).toBeNull();

      // Hunters come from gem ownership, and deactivated profiles are excluded.
      const profileArgs = prisma.profile.findMany.mock.calls[0][0];
      expect(profileArgs.where.id.in.sort()).toEqual(
        [ADMIN, HUNTER, OTHER].sort(),
      );
      expect(profileArgs.where.isDeactivated).toBe(false);
      // Every live gem, no owner filter.
      expect(prisma.project.findMany.mock.calls[0][0].where.OR).toBeUndefined();
    });

    it('uses a fixed number of queries whatever the size', async () => {
      const { service, prisma } = leaderboardService();
      await service.getLeaderboard({});
      expect(totalQueries(prisma)).toBe(9);
    });
  });

  describe('getBoard', () => {
    it('lists every owned gem worst first with its state and deadline', async () => {
      const deadline = new Date(NOW.getTime() + 3 * DAY);
      const { service, prisma } = createService({
        profiles: [profile(HUNTER, 'ada')],
        projects: [
          project('current', {
            listed: 60,
            hunters: [HUNTER],
            name: 'Current',
          }),
          project('due', { listed: 60, hunters: [HUNTER], name: 'Due' }),
          project('quiet-a', {
            listed: 60,
            hunters: [HUNTER],
            name: 'Quiet A',
          }),
          project('quiet-b', {
            listed: 30,
            hunters: [HUNTER],
            name: 'Quiet B',
          }),
        ],
        lastUpdates: {
          current: daysAgo(2),
          due: daysAgo(11),
          'quiet-a': daysAgo(20),
        },
        lastUpdateRows: [
          {
            id: 'u-cur',
            projectId: 'current',
            title: 'Mainnet',
            createdAt: daysAgo(2),
          },
          {
            id: 'u-due',
            projectId: 'due',
            title: 'Audit',
            createdAt: daysAgo(11),
          },
          {
            id: 'u-qa',
            projectId: 'quiet-a',
            title: 'Old',
            createdAt: daysAgo(20),
          },
        ],
        asks: [
          { projectId: 'quiet-b', createdAt: daysAgo(1) },
          { projectId: 'quiet-b', createdAt: daysAgo(2) },
          { projectId: 'current', createdAt: daysAgo(30) },
        ],
        openReports: { 'quiet-a': 1 },
        followers: { current: 7 },
        deadlines: { current: deadline },
      });

      const board = await service.getBoard(HUNTER);

      expect(board.gems.map((g) => [g.projectId, g.state])).toEqual([
        ['quiet-b', 'quiet'], // 2 members waiting
        ['quiet-a', 'quiet'],
        ['due', 'due'],
        ['current', 'current'],
      ]);
      const current = board.gems[3];
      expect(current).toEqual({
        projectId: 'current',
        name: 'Current',
        logoUrl: null,
        primaryTag: 'DeFi',
        followersCount: 7,
        listedAt: daysAgo(60).toISOString(),
        lastActivityAt: daysAgo(2).toISOString(),
        lastUpdate: {
          id: 'u-cur',
          title: 'Mainnet',
          publishedAt: daysAgo(2).toISOString(),
        },
        daysQuiet: 2,
        state: 'current',
        membersWaiting: 0,
        openReports: 0,
        nextDeadlineAt: deadline.toISOString(),
      });
      const neverUpdated = board.gems[0];
      expect(neverUpdated.lastUpdate).toBeNull();
      expect(neverUpdated.daysQuiet).toBe(30);
      expect(neverUpdated.membersWaiting).toBe(2);

      expect(board.reliability).toMatchObject({
        profileId: HUNTER,
        gemsOwned: 4,
        coverage: 0.5,
        standing: 'slipping',
        membersWaiting: 2,
        openReports: 1,
      });

      // Newest-update rows are fetched in one query keyed by (gem, timestamp).
      const rowsQuery = prisma.update.findMany.mock.calls.find(
        (call: any[]) => call[0].where.OR,
      )[0];
      expect(rowsQuery.where.OR).toHaveLength(3);
      // profile, gems, 7 fact reads, deadlines, newest-update rows.
      expect(totalQueries(prisma)).toBe(11);
    });
  });

  describe('ownerReliabilityFor', () => {
    it('summarises the primary owner of each gem in two queries', async () => {
      const { service, prisma } = createService({
        profiles: [],
        projects: [
          project('a1', { listed: 60, hunters: [HUNTER] }),
          project('r1', { listed: 60, owner: ADMIN }),
        ],
        lastUpdates: { a1: daysAgo(1) },
      });

      const result = await service.ownerReliabilityFor([
        { id: 'a1', ownerAdminId: ADMIN, hunters: [{ hunterId: HUNTER }] },
        { id: 'r1', ownerAdminId: ADMIN, hunters: [] },
      ]);

      expect(result.get('a1')).toEqual({
        profileId: HUNTER,
        standing: 'reliable',
        coverage: 1,
      });
      expect(result.get('r1')).toEqual({
        profileId: ADMIN,
        standing: 'quiet',
        coverage: 0,
      });
      expect(totalQueries(prisma)).toBe(2);
    });
  });
});
