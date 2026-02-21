import { ConfigService } from '@nestjs/config';
import { UpdateUrgency } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { MeRadarService } from './me-radar.service';

describe('MeRadarService', () => {
  const prisma = {
    profile: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    update: {
      findMany: jest.fn(),
    },
  };

  const configService = {
    get: jest.fn().mockReturnValue(true),
  } as unknown as ConfigService;

  const auditLogService = {
    create: jest.fn(),
  } as unknown as AuditLogService;

  let service: MeRadarService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new MeRadarService(prisma as any, configService, auditLogService);
  });

  it('returns zero counts when there are no new followed updates', async () => {
    const seenAt = new Date('2026-02-20T00:00:00.000Z');
    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-1',
      homeFeedLastSeenAt: seenAt,
      follows: [{ projectId: 'project-1' }],
    });
    prisma.update.findMany.mockResolvedValue([]);

    const result = await service.getRadar('user-1');

    expect(result.lastSeenAt).toEqual(seenAt);
    expect(result.newUpdatesCount).toBe(0);
    expect(result.highUrgencyCount).toBe(0);
    expect(result.activeProjects).toEqual([]);
  });

  it('returns non-zero counts when followed updates exist after last seen', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-1',
      homeFeedLastSeenAt: new Date('2026-02-20T00:00:00.000Z'),
      follows: [{ projectId: 'project-1' }],
    });
    prisma.update.findMany.mockResolvedValue([
      {
        projectId: 'project-1',
        urgency: UpdateUrgency.high,
        createdAt: new Date('2026-02-20T03:00:00.000Z'),
        project: { name: 'Blocnet' },
      },
      {
        projectId: 'project-1',
        urgency: UpdateUrgency.low,
        createdAt: new Date('2026-02-20T02:00:00.000Z'),
        project: { name: 'Blocnet' },
      },
    ]);

    const result = await service.getRadar('user-1');

    expect(result.newUpdatesCount).toBe(2);
    expect(result.highUrgencyCount).toBe(1);
    expect(result.activeProjects).toEqual([
      expect.objectContaining({
        projectId: 'project-1',
        projectName: 'Blocnet',
        newCount: 2,
        highCount: 1,
      }),
    ]);
  });

  it('acknowledges radar and records audit log event', async () => {
    const seenAt = new Date('2026-02-20T05:00:00.000Z');
    prisma.profile.update.mockResolvedValue({
      id: 'user-1',
      homeFeedLastSeenAt: seenAt,
    });

    const result = await service.ack('user-1', seenAt.toISOString());

    expect(prisma.profile.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user-1' },
        data: { homeFeedLastSeenAt: seenAt },
      }),
    );
    expect(auditLogService.create).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: 'user-1',
        action: 'radar.ack',
      }),
    );
    expect(result).toEqual({
      ok: true,
      seenAt,
    });
  });
});
