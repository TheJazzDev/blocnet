import { ConfigService } from '@nestjs/config';
import { UpdateUrgency } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { EdgeFeedbackAction } from './dto/edge-feedback.dto';
import { EdgeEngineService } from './edge-engine.service';

describe('EdgeEngineService', () => {
  const prisma = {
    profile: {
      findUnique: jest.fn(),
    },
    update: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
    },
    edgeConfig: {
      upsert: jest.fn(),
    },
  };

  const configService = {
    get: jest.fn().mockImplementation((_: string, fallback: unknown) => fallback),
  } as unknown as ConfigService;

  const auditLogService = {
    create: jest.fn(),
  } as unknown as AuditLogService;

  let service: EdgeEngineService;

  beforeEach(() => {
    jest.clearAllMocks();
    (configService.get as jest.Mock).mockImplementation(
      (_: string, fallback: unknown) => fallback,
    );
    prisma.edgeConfig.upsert.mockResolvedValue({
      id: 'default',
      enabled: true,
      updatedAt: new Date('2026-02-23T00:00:00.000Z'),
    });
    service = new EdgeEngineService(prisma as any, configService, auditLogService);
  });

  it('ranks higher urgency and fresher updates first in feed', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-1',
      follows: [{ projectId: 'project-1', alertMinUrgency: UpdateUrgency.low }],
    });
    prisma.update.findMany.mockResolvedValue([
      {
        id: 'update-low-old',
        projectId: 'project-1',
        title: 'Old low urgency',
        urgency: UpdateUrgency.low,
        createdAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000),
        secondaryTags: [],
        project: { id: 'project-1', name: 'Alpha', slug: 'alpha' },
      },
      {
        id: 'update-high-fresh',
        projectId: 'project-1',
        title: 'Fresh high urgency',
        urgency: UpdateUrgency.high,
        createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
        secondaryTags: [{ secondaryTagId: 'tag-1' }],
        project: { id: 'project-1', name: 'Alpha', slug: 'alpha' },
      },
    ]);

    const result = await service.getFeed('user-1', { limit: 2 });

    expect(result.items).toHaveLength(2);
    expect(result.items[0].decisionId).toBe('edge:update:update-high-fresh');
    expect(result.items[0].recommendedAction).toBe(EdgeFeedbackAction.act);
    expect(result.items[0].edgeScore).toBeGreaterThan(result.items[1].edgeScore);
  });

  it('returns explainability payload for a tracked decision', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-1',
      follows: [{ projectId: 'project-1', alertMinUrgency: UpdateUrgency.medium }],
    });
    prisma.update.findFirst.mockResolvedValue({
      id: 'update-1',
      projectId: 'project-1',
      title: 'Protocol upgrade',
      urgency: UpdateUrgency.high,
      createdAt: new Date(Date.now() - 60 * 60 * 1000),
      secondaryTags: [{ secondaryTagId: 'tag-1' }],
      project: { id: 'project-1', name: 'Blocnet', slug: 'blocnet' },
    });

    const result = await service.explain('user-1', 'edge:update:update-1');

    expect(result.decisionId).toBe('edge:update:update-1');
    expect(result.explanation.edgeScore).toBeGreaterThan(0);
    expect(result.explanation.reasonCodes.length).toBeGreaterThan(0);
  });

  it('records feedback actions into audit log', async () => {
    const result = await service.feedback('user-1', {
      decisionId: 'edge:update:update-1',
      action: EdgeFeedbackAction.watch,
      context: { surface: 'home_edge_feed' },
    });

    expect(auditLogService.create).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: 'user-1',
        action: 'edge.feedback.watch',
        resourceType: 'edge_decision',
        resourceId: 'edge:update:update-1',
      }),
    );
    expect(result.ok).toBe(true);
    expect(result.action).toBe(EdgeFeedbackAction.watch);
  });

  it('returns disabled response for feedback when BEE is off', async () => {
    prisma.edgeConfig.upsert.mockResolvedValueOnce({
      id: 'default',
      enabled: false,
      updatedAt: new Date('2026-02-23T00:00:00.000Z'),
    });

    const result = await service.feedback('user-1', {
      decisionId: 'edge:update:update-1',
      action: EdgeFeedbackAction.watch,
      context: { surface: 'home_edge_feed' },
    });

    expect(result.ok).toBe(false);
    expect(result.persisted).toBe(false);
    expect(auditLogService.create).not.toHaveBeenCalled();
  });

  it('updates BEE config from admin without restart', async () => {
    prisma.edgeConfig.upsert.mockResolvedValueOnce({
      id: 'default',
      enabled: false,
      updatedAt: new Date('2026-02-23T13:45:00.000Z'),
    });

    const result = await service.updateAdminConfig('owner-1', {
      enabled: false,
    });

    expect(prisma.edgeConfig.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'default' },
        update: { enabled: false },
        create: expect.objectContaining({
          id: 'default',
          enabled: false,
        }),
      }),
    );
    expect(auditLogService.create).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: 'owner-1',
        action: 'edge.admin.config.update',
        resourceType: 'edge_config',
        resourceId: 'default',
      }),
    );
    expect(result.enabled).toBe(false);
  });

  it('uses stable cursor pagination with createdAt and id tie-breaker', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-1',
      follows: [{ projectId: 'project-1', alertMinUrgency: UpdateUrgency.low }],
    });

    const sameTimestamp = new Date('2026-02-23T12:00:00.000Z');
    prisma.update.findMany
      .mockResolvedValueOnce([
        {
          id: 'update-b',
          projectId: 'project-1',
          title: 'B decision',
          urgency: UpdateUrgency.low,
          createdAt: sameTimestamp,
          secondaryTags: [],
          project: { id: 'project-1', name: 'Alpha', slug: 'alpha' },
        },
      ])
      .mockResolvedValueOnce([
        {
          id: 'update-a',
          projectId: 'project-1',
          title: 'A decision',
          urgency: UpdateUrgency.medium,
          createdAt: sameTimestamp,
          secondaryTags: [],
          project: { id: 'project-1', name: 'Alpha', slug: 'alpha' },
        },
      ]);

    const firstPage = await service.getFeed('user-1', { limit: 1 });
    expect(firstPage.items).toHaveLength(1);
    expect(firstPage.items[0].update.id).toBe('update-b');
    expect(firstPage.nextCursor).toBe(
      `${sameTimestamp.toISOString()}|update-b`,
    );

    const secondPage = await service.getFeed('user-1', {
      limit: 1,
      cursor: firstPage.nextCursor ?? undefined,
    });

    expect(secondPage.items).toHaveLength(1);
    expect(secondPage.items[0].update.id).toBe('update-a');
    expect(prisma.update.findMany).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({ take: 1 }),
    );
    expect(prisma.update.findMany).toHaveBeenNthCalledWith(
      2,
      expect.objectContaining({
        where: expect.objectContaining({
          OR: [
            {
              createdAt: { lt: sameTimestamp },
            },
            {
              createdAt: sameTimestamp,
              id: { lt: 'update-b' },
            },
          ],
        }),
      }),
    );
  });
});
