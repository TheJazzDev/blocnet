import { UpdateUrgency } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { QuestsService } from '../quests/quests.service';
import { RuntimeFeatureFlagsService } from '../runtime-flags/runtime-feature-flags.service';
import { FollowsService } from './follows.service';

describe('FollowsService', () => {
  const prisma = {
    project: {
      findUnique: jest.fn(),
    },
    projectFollow: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
  };

  const runtimeFeatureFlagsService = {
    isFollowPrefsEnabled: jest.fn().mockReturnValue(true),
  } as unknown as RuntimeFeatureFlagsService;

  const auditLogService = {
    create: jest.fn(),
  } as unknown as AuditLogService;
  const questsService = {
    checkAndCompleteByAction: jest.fn(),
  } as unknown as QuestsService;

  let service: FollowsService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new FollowsService(
      prisma as any,
      runtimeFeatureFlagsService,
      auditLogService,
      questsService,
    );
  });

  it('returns default preferences when follow record does not exist', async () => {
    prisma.projectFollow.findUnique.mockResolvedValue(null);

    const result = await service.getFollowPreferences('user-1', 'project-1');

    expect(result).toEqual({
      projectId: 'project-1',
      userId: 'user-1',
      alertMinUrgency: UpdateUrgency.low,
      mutedUntil: null,
    });
  });

  it('persists follow preferences and logs audit event', async () => {
    const mutedUntilIso = '2026-02-21T10:00:00.000Z';
    const mutedUntil = new Date(mutedUntilIso);
    prisma.project.findUnique.mockResolvedValue({ id: 'project-1' });
    prisma.projectFollow.upsert.mockResolvedValue({
      id: 'follow-1',
      projectId: 'project-1',
      userId: 'user-1',
      alertMinUrgency: UpdateUrgency.medium,
      mutedUntil,
    });

    const result = await service.updateFollowPreferences(
      'user-1',
      'project-1',
      {
        alertMinUrgency: UpdateUrgency.medium,
        mutedUntil: mutedUntilIso,
      },
    );

    expect(prisma.projectFollow.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          projectId_userId: {
            projectId: 'project-1',
            userId: 'user-1',
          },
        },
        update: expect.objectContaining({
          alertMinUrgency: UpdateUrgency.medium,
        }),
      }),
    );
    expect(auditLogService.create).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: 'user-1',
        action: 'follow.preferences.update',
      }),
    );
    expect(result).toEqual(
      expect.objectContaining({
        id: 'follow-1',
        alertMinUrgency: UpdateUrgency.medium,
      }),
    );
  });
});
