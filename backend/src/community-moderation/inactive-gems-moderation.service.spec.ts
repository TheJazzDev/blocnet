import { BadRequestException, NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { AppRole } from '../common/enums/role.enum';
import { ResolveInactiveGemDto } from './dto/resolve-inactive-gem.dto';
import {
  INACTIVE_GEMS_RESOLVED_ACTION,
  InactiveGemsModerationService,
} from './inactive-gems-moderation.service';
import { escalations } from './inactive-gems.waiting';

const NOW = new Date('2026-09-16T12:00:00.000Z');
const DAY = 24 * 60 * 60 * 1000;
const daysAgo = (n: number) => new Date(NOW.getTime() - n * DAY);

class FixedClock extends InactiveGemsModerationService {
  protected now() {
    return NOW;
  }
}

const MODERATOR = {
  id: 'mod-1',
  email: 'mod@blocnet.app',
  roles: [AppRole.COMMUNITY_MODERATOR],
} as any;

/** [n] asks on one gem, a minute apart, the newest at [newest]. */
function asksOn(projectId: string, n: number, newest: Date) {
  return Array.from({ length: n }, (_, i) => ({
    projectId,
    createdAt: new Date(newest.getTime() - i * 60_000),
  }));
}

function project(id: string, name = id) {
  return {
    id,
    name,
    slug: id,
    status: 'active',
    createdAt: daysAgo(60),
    ownerAdminId: 'admin-1',
    primaryTag: { name: 'DeFi' },
    hunters: [],
  };
}

function createService() {
  const prisma = {
    projectInactivityReport: {
      groupBy: jest.fn(),
      updateMany: jest.fn(),
    },
    project: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    projectHunter: { deleteMany: jest.fn(), create: jest.fn() },
    projectUpdateRequest: {
      groupBy: jest.fn().mockResolvedValue([]),
      findMany: jest.fn().mockResolvedValue([]),
    },
    auditLog: { groupBy: jest.fn().mockResolvedValue([]) },
  } as any;
  const auditLog = { create: jest.fn().mockResolvedValue(undefined) } as any;
  const reliability = { standingsFor: jest.fn() } as any;
  const loader = {
    loadLastUpdateAt: jest.fn().mockResolvedValue(new Map()),
    loadProfiles: jest.fn().mockResolvedValue([]),
  } as any;
  const service = new FixedClock(prisma, auditLog, reliability, loader);
  return { service, prisma, auditLog, reliability, loader };
}

describe('InactiveGemsModerationService', () => {
  describe('listQueue', () => {
    it('returns an empty page without further reads when nothing is open', async () => {
      const { service, prisma } = createService();
      prisma.projectInactivityReport.groupBy.mockResolvedValue([]);

      await expect(service.listQueue({})).resolves.toEqual({
        data: [],
        total: 0,
        limit: 30,
        offset: 0,
      });
      expect(prisma.project.findMany).not.toHaveBeenCalled();
    });

    it('lists reported gems with owners, standing and quiet time, most-reported first', async () => {
      const { service, prisma, reliability, loader } = createService();
      prisma.projectInactivityReport.groupBy.mockResolvedValue([
        {
          projectId: 'p1',
          _count: { _all: 1 },
          _min: { createdAt: daysAgo(3) },
        },
        {
          projectId: 'p2',
          _count: { _all: 4 },
          _min: { createdAt: daysAgo(9) },
        },
      ]);
      prisma.project.findMany.mockResolvedValue([
        {
          id: 'p1',
          name: 'Alpha',
          slug: 'alpha',
          status: 'active',
          createdAt: daysAgo(100),
          ownerAdminId: 'admin-1',
          primaryTag: { name: 'DeFi' },
          hunters: [{ hunterId: 'hunter-1' }],
        },
        {
          id: 'p2',
          name: 'Beta',
          slug: 'beta',
          status: 'paused',
          createdAt: daysAgo(40),
          ownerAdminId: 'admin-1',
          primaryTag: { name: 'L2' },
          hunters: [],
        },
      ]);
      loader.loadLastUpdateAt.mockResolvedValue(new Map([['p1', daysAgo(20)]]));
      loader.loadProfiles.mockResolvedValue([
        {
          id: 'hunter-1',
          username: 'ada',
          displayName: 'Ada',
          avatarUrl: null,
          currentLevel: null,
        },
      ]);
      // p1 last posted 20 days ago, so its 6 asks this week all wait; p2's
      // lone ask is older than the cooldown and does not.
      prisma.projectUpdateRequest.findMany.mockResolvedValue([
        ...Array.from({ length: 6 }, () => ({
          projectId: 'p1',
          createdAt: daysAgo(2),
        })),
        { projectId: 'p2', createdAt: daysAgo(8) },
      ]);
      reliability.standingsFor.mockResolvedValue(
        new Map([
          ['hunter-1', { standing: 'quiet', coverage: 0.25 }],
          ['admin-1', { standing: 'slipping', coverage: 0.5 }],
        ]),
      );

      const result = await service.listQueue({});

      expect(result.total).toBe(2);
      expect(result.data.map((item) => item.project.id)).toEqual(['p2', 'p1']);

      const [beta, alpha] = result.data;
      // No hunter assigned: the owning admin answers for it.
      expect(beta.hunters).toEqual([
        {
          id: 'admin-1',
          username: null,
          displayName: null,
          avatarUrl: null,
          standing: 'slipping',
          coverage: 0.5,
        },
      ]);
      // Never updated: quiet since listing.
      expect(beta.daysQuiet).toBe(40);
      expect(beta.lastActivityAt).toBe(daysAgo(40).toISOString());
      expect(beta.project.status).toBe('paused');

      expect(alpha).toMatchObject({
        project: { id: 'p1', name: 'Alpha', slug: 'alpha', primaryTag: 'DeFi' },
        hunters: [{ id: 'hunter-1', username: 'ada', standing: 'quiet' }],
        openReports: 1,
        firstReportedAt: daysAgo(3).toISOString(),
        daysQuiet: 20,
        membersWaiting: 6,
      });
      expect(beta.membersWaiting).toBe(0);

      expect(reliability.standingsFor).toHaveBeenCalledWith([
        'hunter-1',
        'admin-1',
      ]);
      // Batched: one project read for the whole queue.
      expect(prisma.project.findMany).toHaveBeenCalledTimes(1);
      expect(prisma.project.findMany.mock.calls[0][0].where).toEqual({
        id: { in: ['p1', 'p2'] },
      });
    });

    it('counts only asks made after the gem’s latest update as waiting', async () => {
      const { service, prisma, reliability, loader } = createService();
      prisma.projectInactivityReport.groupBy.mockResolvedValue([
        {
          projectId: 'p1',
          _count: { _all: 1 },
          _min: { createdAt: daysAgo(3) },
        },
      ]);
      prisma.project.findMany.mockResolvedValue([
        {
          id: 'p1',
          name: 'Alpha',
          slug: 'alpha',
          status: 'active',
          createdAt: daysAgo(100),
          ownerAdminId: 'admin-1',
          primaryTag: { name: 'DeFi' },
          hunters: [],
        },
      ]);
      loader.loadLastUpdateAt.mockResolvedValue(new Map([['p1', daysAgo(2)]]));
      prisma.projectUpdateRequest.findMany.mockResolvedValue([
        { projectId: 'p1', createdAt: daysAgo(5) }, // before the post: cleared
        { projectId: 'p1', createdAt: daysAgo(2) }, // same instant: cleared
        { projectId: 'p1', createdAt: daysAgo(1) }, // after: waiting
      ]);
      reliability.standingsFor.mockResolvedValue(new Map());

      const result = await service.listQueue({});
      expect(result.data[0].membersWaiting).toBe(1);
    });

    it('queues a gem for waiting alone, cleared by updates and by a resolution', async () => {
      const { service, prisma, reliability, loader } = createService();
      prisma.projectInactivityReport.groupBy.mockResolvedValue([
        {
          projectId: 'rep',
          _count: { _all: 1 },
          _min: { createdAt: daysAgo(1) },
        },
      ]);
      // Candidates: at least 50 asks this week, before any clearing.
      prisma.projectUpdateRequest.groupBy.mockResolvedValue([
        { projectId: 'waits' },
        { projectId: 'posted' },
        { projectId: 'handled' },
      ]);
      prisma.projectUpdateRequest.findMany.mockResolvedValue([
        ...asksOn('waits', 50, daysAgo(1)),
        ...asksOn('posted', 60, daysAgo(4)), // all before the post
        ...asksOn('handled', 70, daysAgo(4)), // all before the resolution
        ...asksOn('handled', 5, daysAgo(1)),
      ]);
      loader.loadLastUpdateAt.mockResolvedValue(
        new Map([['posted', daysAgo(3)]]),
      );
      prisma.auditLog.groupBy.mockResolvedValue([
        { resourceId: 'handled', _max: { createdAt: daysAgo(2) } },
      ]);
      prisma.project.findMany.mockResolvedValue([
        project('rep'),
        project('waits'),
      ]);
      reliability.standingsFor.mockResolvedValue(new Map());

      const result = await service.listQueue({});

      expect(prisma.project.findMany.mock.calls[0][0].where.id.in).toEqual([
        'rep',
        'waits',
      ]);
      const byId = Object.fromEntries(
        result.data.map((item) => [item.project.id, item]),
      );
      expect(byId.rep).toMatchObject({ reasons: ['reports'], openReports: 1 });
      expect(byId.waits).toMatchObject({
        reasons: ['waiting'],
        openReports: 0,
        membersWaiting: 50,
        // The earliest ask in the wait stands in for a first report.
        firstReportedAt: new Date(
          daysAgo(1).getTime() - 49 * 60_000,
        ).toISOString(),
      });
      // Only moderator resolutions clear the escalation, and only this week's.
      const auditWhere = prisma.auditLog.groupBy.mock.calls[0][0].where;
      expect(auditWhere).toMatchObject({
        action: INACTIVE_GEMS_RESOLVED_ACTION,
        resourceType: 'project',
        createdAt: { gte: daysAgo(7) },
      });
      expect(
        prisma.projectUpdateRequest.groupBy.mock.calls[0][0].having,
      ).toEqual({ projectId: { _count: { gte: 50 } } });
    });

    it('marks a reported gem that is also escalated with both reasons, and sorts ties by waiting', async () => {
      const { service, prisma, reliability } = createService();
      prisma.projectInactivityReport.groupBy.mockResolvedValue([
        {
          projectId: 'x',
          _count: { _all: 2 },
          _min: { createdAt: daysAgo(1) },
        },
        {
          projectId: 'y',
          _count: { _all: 2 },
          _min: { createdAt: daysAgo(1) },
        },
      ]);
      prisma.projectUpdateRequest.groupBy.mockResolvedValue([
        { projectId: 'y' },
      ]);
      prisma.projectUpdateRequest.findMany.mockResolvedValue([
        ...asksOn('x', 3, daysAgo(1)),
        ...asksOn('y', 51, daysAgo(1)),
      ]);
      prisma.project.findMany.mockResolvedValue([project('x'), project('y')]);
      reliability.standingsFor.mockResolvedValue(new Map());

      const result = await service.listQueue({});
      expect(
        result.data.map((i) => [i.project.id, i.reasons, i.membersWaiting]),
      ).toEqual([
        ['y', ['reports', 'waiting'], 51],
        ['x', ['reports'], 3],
      ]);
      // reports, candidates, last updates, asks, resolutions, projects,
      // profiles (mocked loader), standings (mocked) — fixed.
      expect(prisma.projectInactivityReport.groupBy).toHaveBeenCalledTimes(1);
      expect(prisma.projectUpdateRequest.findMany).toHaveBeenCalledTimes(1);
      expect(prisma.auditLog.groupBy).toHaveBeenCalledTimes(1);
      expect(prisma.project.findMany).toHaveBeenCalledTimes(1);
    });

    it('pages after sorting', async () => {
      const { service, prisma, reliability } = createService();
      prisma.projectInactivityReport.groupBy.mockResolvedValue(
        ['a', 'b', 'c'].map((id, i) => ({
          projectId: id,
          _count: { _all: i + 1 },
          _min: { createdAt: daysAgo(1) },
        })),
      );
      prisma.project.findMany.mockResolvedValue(
        ['a', 'b', 'c'].map((id) => ({
          id,
          name: id,
          slug: id,
          status: 'active',
          createdAt: daysAgo(30),
          ownerAdminId: 'admin-1',
          primaryTag: { name: 'x' },
          hunters: [],
        })),
      );
      reliability.standingsFor.mockResolvedValue(new Map());

      const page = await service.listQueue({ offset: 1, limit: 1 });
      expect(page.data.map((item) => item.project.id)).toEqual(['b']);
      expect(page).toMatchObject({ total: 3, offset: 1, limit: 1 });
    });
  });

  describe('resolve', () => {
    it('closes every open report and audits the outcome without touching the gem', async () => {
      const { service, prisma, auditLog } = createService();
      prisma.project.findUnique.mockResolvedValue({
        id: 'p1',
        ownerAdminId: 'admin-1',
        hunters: [{ hunterId: 'hunter-1' }],
      });
      prisma.projectInactivityReport.updateMany.mockResolvedValue({ count: 3 });

      const result = await service.resolve(MODERATOR, 'p1', {
        outcome: 'hunter_contacted',
        note: '  Messaged the hunter; update promised Friday.  ',
      });

      expect(result).toEqual({
        ok: true,
        projectId: 'p1',
        resolvedCount: 3,
        outcome: 'hunter_contacted',
      });
      expect(prisma.projectInactivityReport.updateMany).toHaveBeenCalledWith({
        where: { projectId: 'p1', resolvedAt: null },
        data: { resolvedAt: NOW, resolvedBy: 'mod-1' },
      });
      expect(auditLog.create).toHaveBeenCalledWith({
        actorId: 'mod-1',
        action: INACTIVE_GEMS_RESOLVED_ACTION,
        resourceType: 'project',
        resourceId: 'p1',
        metadata: {
          outcome: 'hunter_contacted',
          note: 'Messaged the hunter; update promised Friday.',
          reasons: ['reports'],
          resolvedCount: 3,
          membersWaiting: null,
          hunterIds: ['hunter-1'],
        },
      });
      // Reassignment is a person's decision in the console, never this.
      expect(prisma.project.update).not.toHaveBeenCalled();
      expect(prisma.projectHunter.deleteMany).not.toHaveBeenCalled();
      expect(prisma.projectHunter.create).not.toHaveBeenCalled();
    });

    it('404s for an unknown gem', async () => {
      const { service, prisma } = createService();
      prisma.project.findUnique.mockResolvedValue(null);
      await expect(
        service.resolve(MODERATOR, 'nope', {
          outcome: 'no_action',
          note: 'ok ok',
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(prisma.projectInactivityReport.updateMany).not.toHaveBeenCalled();
    });

    it('resolves a gem queued only for waiting by auditing it, without deleting asks', async () => {
      const { service, prisma, auditLog } = createService();
      prisma.project.findUnique.mockResolvedValue({
        id: 'p1',
        ownerAdminId: 'admin-1',
        hunters: [{ hunterId: 'hunter-1' }],
      });
      prisma.projectUpdateRequest.groupBy.mockResolvedValue([
        { projectId: 'p1' },
      ]);
      prisma.projectUpdateRequest.findMany.mockResolvedValue(
        asksOn('p1', 55, daysAgo(1)),
      );
      prisma.projectInactivityReport.updateMany.mockResolvedValue({ count: 0 });

      const result = await service.resolve(MODERATOR, 'p1', {
        outcome: 'escalated',
        note: 'Sent to admins for reassignment',
      });

      expect(result).toEqual({
        ok: true,
        projectId: 'p1',
        resolvedCount: 0,
        outcome: 'escalated',
      });
      // The escalation check is scoped to this gem.
      expect(
        prisma.projectUpdateRequest.groupBy.mock.calls[0][0].where.projectId,
      ).toEqual({ in: ['p1'] });
      expect(auditLog.create.mock.calls[0][0]).toMatchObject({
        action: INACTIVE_GEMS_RESOLVED_ACTION,
        resourceId: 'p1',
        metadata: {
          outcome: 'escalated',
          reasons: ['waiting'],
          resolvedCount: 0,
          membersWaiting: 55,
        },
      });
      expect(prisma.projectUpdateRequest).not.toHaveProperty('deleteMany');
    });

    it('404s when the gem has no open reports, and writes no audit entry', async () => {
      const { service, prisma, auditLog } = createService();
      prisma.project.findUnique.mockResolvedValue({
        id: 'p1',
        ownerAdminId: 'admin-1',
        hunters: [],
      });
      prisma.projectInactivityReport.updateMany.mockResolvedValue({ count: 0 });
      await expect(
        service.resolve(MODERATOR, 'p1', { outcome: 'escalated', note: 'dup' }),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(auditLog.create).not.toHaveBeenCalled();
    });

    it('rejects a note that is only whitespace', async () => {
      const { service, prisma } = createService();
      prisma.project.findUnique.mockResolvedValue({
        id: 'p1',
        ownerAdminId: 'admin-1',
        hunters: [],
      });
      await expect(
        service.resolve(MODERATOR, 'p1', {
          outcome: 'no_action',
          note: '     ',
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.projectInactivityReport.updateMany).not.toHaveBeenCalled();
    });
  });

  describe('ResolveInactiveGemDto', () => {
    const errorsFor = async (body: object) =>
      (await validate(plainToInstance(ResolveInactiveGemDto, body))).map(
        (e) => e.property,
      );

    it('requires a known outcome and a note', async () => {
      expect(
        await errorsFor({ outcome: 'escalated', note: 'Sent to admins' }),
      ).toEqual([]);
      expect(
        await errorsFor({ outcome: 'reassign', note: 'Sent to admins' }),
      ).toEqual(['outcome']);
      expect(await errorsFor({ outcome: 'no_action' })).toEqual(['note']);
      expect(
        await errorsFor({ outcome: 'no_action', note: 'x'.repeat(501) }),
      ).toEqual(['note']);
    });
  });

  describe('countOpen', () => {
    it('counts gems, not reports', async () => {
      const { service, prisma } = createService();
      prisma.projectInactivityReport.groupBy.mockResolvedValue([
        { projectId: 'a' },
        { projectId: 'b' },
      ]);
      await expect(service.countOpen()).resolves.toBe(2);
    });

    it('adds gems escalated for waiting, once each', async () => {
      const { service, prisma } = createService();
      prisma.projectInactivityReport.groupBy.mockResolvedValue([
        { projectId: 'a' },
        { projectId: 'b' },
      ]);
      prisma.projectUpdateRequest.groupBy.mockResolvedValue([
        { projectId: 'b' },
        { projectId: 'c' },
        { projectId: 'd' },
      ]);
      prisma.projectUpdateRequest.findMany.mockResolvedValue([
        ...asksOn('b', 50, daysAgo(1)),
        ...asksOn('c', 50, daysAgo(1)),
        ...asksOn('d', 49, daysAgo(1)), // under the threshold after all
      ]);
      await expect(service.countOpen()).resolves.toBe(3);
    });
  });

  describe('escalations', () => {
    it('keeps gems at or over 50 asks after their clearing instant', () => {
      const toEvents = (rows: { projectId: string; createdAt: Date }[]) =>
        rows.map((r) => ({ projectId: r.projectId, at: r.createdAt }));
      const asks = toEvents([
        ...asksOn('a', 50, daysAgo(1)),
        ...asksOn('b', 60, daysAgo(3)),
        ...asksOn('b', 10, daysAgo(1)),
      ]);
      const result = escalations(asks, new Map([['b', daysAgo(2)]]), NOW);
      expect([...result.keys()]).toEqual(['a']);
      expect(result.get('a')?.waiting).toBe(50);
    });
  });
});
