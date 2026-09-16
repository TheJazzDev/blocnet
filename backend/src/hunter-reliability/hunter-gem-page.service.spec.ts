import { NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { HunterGemPageQuery } from './dto/hunter-gem-page.dto';
import { editedAtOf, HunterGemPageService } from './hunter-gem-page.service';
import { ReliabilityLoader } from './reliability.loader';

const NOW = new Date('2026-09-16T12:00:00.000Z');
const DAY = 24 * 60 * 60 * 1000;
const daysAgo = (n: number) => new Date(NOW.getTime() - n * DAY);

class FixedClock extends HunterGemPageService {
  protected now() {
    return NOW;
  }
}

const HUNTER = '11111111-1111-4111-8111-111111111111';
const OTHER = '22222222-2222-4222-8222-222222222222';
const GEM = '44444444-4444-4444-8444-444444444444';

interface Row {
  id: string;
  title: string;
  urgency: 'high' | 'medium' | 'low';
  createdAt: Date;
  updatedAt: Date;
  moderatedAt: Date | null;
  _count: { comments: number; likes: number };
}

const row = (id: string, at: Date, extra: Partial<Row> = {}): Row => ({
  id,
  title: `Title ${id}`,
  urgency: 'medium',
  createdAt: at,
  updatedAt: at,
  moderatedAt: null,
  _count: { comments: 0, likes: 0 },
  ...extra,
});

function createService(data: {
  hunters: string[];
  rows: Row[];
  asks?: { projectId: string; createdAt: Date }[];
  tips?: Record<string, bigint>;
  currency?: { code: string; decimals: number } | null;
  updatesCount?: number;
  handover?: object | null;
}) {
  const newest = data.rows[0]?.createdAt;
  const prisma = {
    project: {
      findMany: jest.fn().mockResolvedValue([
        {
          id: GEM,
          name: 'Halo Points',
          createdAt: daysAgo(90),
          ownerAdminId: OTHER,
          primaryTag: { name: 'CORE' },
          hunters: data.hunters.map((hunterId) => ({ hunterId })),
        },
      ]),
    },
    update: {
      groupBy: jest.fn().mockImplementation((args: any) => {
        if (args._count) {
          return Promise.resolve([
            { projectId: GEM, _count: { _all: data.updatesCount ?? 0 } },
          ]);
        }
        if (args._min) return Promise.resolve([]);
        return Promise.resolve(
          newest ? [{ projectId: GEM, _max: { createdAt: newest } }] : [],
        );
      }),
      findMany: jest.fn().mockImplementation((args: any) =>
        Promise.resolve(
          args.select._count
            ? data.rows
            : data.rows.map((r) => ({
                projectId: GEM,
                createdAt: r.createdAt,
              })),
        ),
      ),
    },
    projectUpdateRequest: {
      findMany: jest.fn().mockResolvedValue(data.asks ?? []),
    },
    projectHunterInvite: {
      findFirst: jest.fn().mockResolvedValue(data.handover ?? null),
    },
    projectInactivityReport: {
      groupBy: jest
        .fn()
        .mockResolvedValue([{ projectId: GEM, _count: { _all: 2 } }]),
    },
    projectFollow: {
      groupBy: jest
        .fn()
        .mockResolvedValue([{ projectId: GEM, _count: { _all: 4730 } }]),
    },
    tipCurrency: {
      findFirst: jest
        .fn()
        .mockResolvedValue(
          data.currency === undefined
            ? { code: 'BNP', decimals: 2 }
            : data.currency,
        ),
    },
    tipTransaction: {
      groupBy: jest.fn().mockResolvedValue(
        Object.entries(data.tips ?? {}).map(([contextId, sum]) => ({
          contextId,
          _sum: { amountAtomic: sum },
        })),
      ),
    },
  } as any;
  const service = new FixedClock(prisma, new ReliabilityLoader(prisma));
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

describe('HunterGemPageService', () => {
  it('404s when the caller does not keep the gem', async () => {
    const { service } = createService({ hunters: [OTHER], rows: [] });
    await expect(service.getGem(HUNTER, GEM)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('404s for a gem the caller’s gem list does not include', async () => {
    const { service } = createService({ hunters: [HUNTER], rows: [] });
    await expect(
      service.getGem(HUNTER, '55555555-5555-4555-8555-555555555555'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns the board row, the timeline newest first, and the gap for a quiet gem', async () => {
    const { service, prisma } = createService({
      hunters: [HUNTER],
      updatesCount: 2,
      rows: [
        row('u2', daysAgo(19), {
          urgency: 'high',
          updatedAt: new Date(daysAgo(19).getTime() + 5 * 60_000),
          _count: { comments: 38, likes: 12 },
        }),
        row('u1', daysAgo(30)),
      ],
      asks: [
        { projectId: GEM, createdAt: daysAgo(2) },
        { projectId: GEM, createdAt: daysAgo(3) },
      ],
      tips: { u2: 210000n },
    });

    const page = await service.getGem(HUNTER, GEM, { limit: 5 });

    expect(page.gem).toMatchObject({
      projectId: GEM,
      name: 'Halo Points',
      chain: 'CORE',
      followersCount: 4730,
      state: 'quiet',
      daysQuiet: 19,
      membersWaiting: 2,
      openReports: 2,
      updatesCount: 2,
      neverUpdated: false,
      escalatesAtWaiting: 50,
      lastUpdate: {
        id: 'u2',
        title: 'Title u2',
        publishedAt: daysAgo(19).toISOString(),
      },
    });
    expect(page.gem.pendingHandover).toBeNull();
    expect(page.gapDays).toBe(19);
    expect(page.updates).toEqual([
      {
        id: 'u2',
        title: 'Title u2',
        priority: 'high',
        createdAt: daysAgo(19).toISOString(),
        editedAt: new Date(daysAgo(19).getTime() + 5 * 60_000).toISOString(),
        likesCount: 12,
        commentsCount: 38,
        tipsAtomic: '210000',
        tipsCurrencyCode: 'BNP',
        tipsCurrencyDecimals: 2,
      },
      {
        id: 'u1',
        title: 'Title u1',
        priority: 'medium',
        createdAt: daysAgo(30).toISOString(),
        editedAt: null,
        likesCount: 0,
        commentsCount: 0,
        tipsAtomic: '0',
        tipsCurrencyCode: 'BNP',
        tipsCurrencyDecimals: 2,
      },
    ]);

    const timeline = prisma.update.findMany.mock.calls.find(
      (call: any[]) => call[0].select._count,
    )[0];
    expect(timeline.where).toEqual({ projectId: GEM, status: 'published' });
    expect(timeline.take).toBe(5);
    expect(timeline.orderBy).toEqual([{ createdAt: 'desc' }, { id: 'asc' }]);
    // Likes are counted inside the timeline read, not per update.
    expect(timeline.select._count).toEqual({
      select: { comments: true, likes: true },
    });

    expect(prisma.tipTransaction.groupBy).toHaveBeenCalledWith({
      by: ['contextId'],
      where: {
        contextType: 'update',
        contextId: { in: ['u2', 'u1'] },
        currencyCode: 'BNP',
        type: 'tip',
      },
      _sum: { amountAtomic: true },
    });
    expect(totalQueries(prisma)).toBe(12);
  });

  it('has no gap for a current gem and none for a gem never updated', async () => {
    const current = createService({
      hunters: [HUNTER],
      rows: [row('u1', daysAgo(2))],
    });
    expect((await current.service.getGem(HUNTER, GEM)).gapDays).toBeNull();

    const never = createService({ hunters: [HUNTER], rows: [] });
    const page = await never.service.getGem(HUNTER, GEM);
    expect(page.gem).toMatchObject({
      state: 'quiet',
      neverUpdated: true,
      lastUpdate: null,
    });
    expect(page.gapDays).toBeNull();
    expect(page.updates).toEqual([]);
    // No updates, no tip read.
    expect(never.prisma.tipTransaction.groupBy).not.toHaveBeenCalled();
  });

  it('lets an owning admin open a gem with no hunters assigned', async () => {
    const { service } = createService({ hunters: [], rows: [] });
    await expect(service.getGem(OTHER, GEM)).resolves.toMatchObject({
      gem: { projectId: GEM },
    });
  });

  it('shows the gem’s open handover', async () => {
    const offeredAt = daysAgo(1);
    const { service, prisma } = createService({
      hunters: [HUNTER],
      rows: [row('u1', daysAgo(2))],
      handover: {
        id: 'inv-1',
        updatedAt: offeredAt,
        hunter: { id: OTHER, username: 'kemi', displayName: 'Kemi' },
      },
    });
    const page = await service.getGem(HUNTER, GEM);
    expect(page.gem.pendingHandover).toEqual({
      inviteId: 'inv-1',
      hunter: { id: OTHER, username: 'kemi', displayName: 'Kemi' },
      createdAt: offeredAt.toISOString(),
    });
    expect(prisma.projectHunterInvite.findFirst.mock.calls[0][0].where).toEqual(
      { projectId: GEM, kind: 'handover', status: 'pending' },
    );
    expect(totalQueries(prisma)).toBe(12);
  });

  it('skips tips when no tipping currency is active', async () => {
    const { service, prisma } = createService({
      hunters: [HUNTER],
      rows: [row('u1', daysAgo(1))],
      currency: null,
    });
    const page = await service.getGem(HUNTER, GEM);
    expect(page.updates[0]).toMatchObject({
      tipsAtomic: '0',
      tipsCurrencyCode: null,
      tipsCurrencyDecimals: null,
    });
    expect(prisma.tipTransaction.groupBy).not.toHaveBeenCalled();
  });

  describe('editedAtOf', () => {
    const created = daysAgo(1);
    it('ignores the write that created the row', () => {
      expect(
        editedAtOf({
          createdAt: created,
          updatedAt: created,
          moderatedAt: null,
        }),
      ).toBeNull();
    });
    it('ignores a moderation change', () => {
      const later = new Date(created.getTime() + DAY / 2);
      expect(
        editedAtOf({
          createdAt: created,
          updatedAt: later,
          moderatedAt: later,
        }),
      ).toBeNull();
    });
    it('reports a later edit', () => {
      const later = new Date(created.getTime() + 60_000);
      expect(
        editedAtOf({ createdAt: created, updatedAt: later, moderatedAt: null }),
      ).toEqual(later);
    });
  });

  describe('HunterGemPageQuery', () => {
    const errorsFor = async (body: object) =>
      (await validate(plainToInstance(HunterGemPageQuery, body))).map(
        (e) => e.property,
      );
    it('accepts 1–100 and rejects the rest', async () => {
      expect(await errorsFor({})).toEqual([]);
      expect(await errorsFor({ limit: '20' })).toEqual([]);
      expect(await errorsFor({ limit: '0' })).toEqual(['limit']);
      expect(await errorsFor({ limit: '101' })).toEqual(['limit']);
    });
  });
});
