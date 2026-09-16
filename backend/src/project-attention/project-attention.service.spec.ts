import { ProjectAttentionService } from './project-attention.service';

const DAY = 24 * 60 * 60 * 1000;

function createService(latestUpdateAt: Date | null) {
  const prisma = {
    project: {
      findUnique: jest
        .fn()
        .mockImplementation((args: any) =>
          Promise.resolve(
            args.select.hunters
              ? { ownerAdminId: 'admin-1', hunters: [{ hunterId: 'hunter-1' }] }
              : { id: 'p1', name: 'Alpha' },
          ),
        ),
    },
    projectFollow: { findUnique: jest.fn().mockResolvedValue({ id: 'f1' }) },
    projectUpdateRequest: {
      findFirst: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockResolvedValue({}),
      count: jest.fn().mockResolvedValue(3),
    },
    projectInactivityReport: { count: jest.fn().mockResolvedValue(2) },
    update: {
      aggregate: jest
        .fn()
        .mockResolvedValue({ _max: { createdAt: latestUpdateAt } }),
    },
  } as any;
  const notifications = { notifyMany: jest.fn().mockResolvedValue([]) } as any;
  const auditLog = { create: jest.fn() } as any;
  const service = new ProjectAttentionService(prisma, notifications, auditLog);
  return { service, prisma, notifications };
}

describe('ProjectAttentionService', () => {
  beforeEach(() => {
    jest.useFakeTimers().setSystemTime(new Date('2026-09-16T12:00:00.000Z'));
  });
  afterEach(() => jest.useRealTimers());

  describe('attentionFor', () => {
    it('counts only asks made after the gem’s latest published update', async () => {
      const posted = new Date(Date.now() - 2 * DAY);
      const { service, prisma } = createService(posted);

      await expect(service.attentionFor('p1')).resolves.toEqual({
        membersWaiting: 3,
        openReports: 2,
      });
      expect(prisma.update.aggregate).toHaveBeenCalledWith({
        where: { projectId: 'p1', status: 'published' },
        _max: { createdAt: true },
      });
      expect(prisma.projectUpdateRequest.count).toHaveBeenCalledWith({
        where: { projectId: 'p1', createdAt: { gt: posted } },
      });
    });

    it('falls back to the cooldown window when the latest update is older', async () => {
      const { service, prisma } = createService(
        new Date(Date.now() - 30 * DAY),
      );
      await service.attentionFor('p1');
      expect(prisma.projectUpdateRequest.count).toHaveBeenCalledWith({
        where: {
          projectId: 'p1',
          createdAt: { gte: new Date(Date.now() - 7 * DAY) },
        },
      });
    });

    it('uses the cooldown window for a gem never updated', async () => {
      const { service, prisma } = createService(null);
      await service.attentionFor('p1');
      expect(
        prisma.projectUpdateRequest.count.mock.calls[0][0].where.createdAt,
      ).toEqual({ gte: new Date(Date.now() - 7 * DAY) });
    });
  });

  describe('requestUpdate', () => {
    it('tells the member the waiting count under the same rule', async () => {
      const posted = new Date(Date.now() - DAY);
      const { service, prisma, notifications } = createService(posted);

      const result = await service.requestUpdate('member-1', 'p1');

      expect(result).toMatchObject({
        ok: true,
        membersWaiting: 3,
        hunterNotified: true,
      });
      expect(prisma.projectUpdateRequest.count).toHaveBeenCalledWith({
        where: { projectId: 'p1', createdAt: { gt: posted } },
      });
      // The per-member cooldown still looks at the whole week.
      expect(
        prisma.projectUpdateRequest.findFirst.mock.calls[0][0].where.createdAt,
      ).toEqual({ gte: new Date(Date.now() - 7 * DAY) });
      expect(notifications.notifyMany.mock.calls[0][0][0].body).toBe(
        '3 members have asked for an update on this gem.',
      );
    });
  });
});
