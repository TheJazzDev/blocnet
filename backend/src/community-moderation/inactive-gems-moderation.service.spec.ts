import { BadRequestException, NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { AppRole } from '../common/enums/role.enum';
import { ResolveInactiveGemDto } from './dto/resolve-inactive-gem.dto';
import {
  INACTIVE_GEMS_RESOLVED_ACTION,
  InactiveGemsModerationService,
} from './inactive-gems-moderation.service';

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
          resolvedCount: 3,
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
  });
});
