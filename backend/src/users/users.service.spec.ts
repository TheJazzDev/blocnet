import { BadRequestException } from '@nestjs/common';
import { UpdateUrgency } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { QuestsService } from '../quests/quests.service';
import { UsersService } from './users.service';
import { UserAvatarService } from './user-avatar.service';

describe('UsersService', () => {
  const prisma = {
    profile: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    auditLog: {
      findMany: jest.fn(),
    },
    update: {
      findMany: jest.fn(),
    },
  };

  const auditLogService = {
    create: jest.fn(),
  } as unknown as AuditLogService;

  const questsService = {
    checkAndCompleteByAction: jest.fn(),
  } as unknown as QuestsService;

  const userAvatarService = {
    resolveAvatarAccessUrl: jest.fn((url: string | null) =>
      Promise.resolve(url),
    ),
    uploadAvatar: jest.fn(),
    deletePreviousAvatarIfManaged: jest.fn(),
    isManagedPublicAvatarUrl: jest.fn().mockReturnValue(false),
  } as unknown as UserAvatarService;

  let service: UsersService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new UsersService(
      prisma as any,
      auditLogService,
      questsService,
      userAvatarService,
    );
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('returns trust metrics on public profile', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-20T12:00:00.000Z'));

    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-1',
      displayName: 'Hunter One',
      avatarUrl: 'https://img.example/hunter.png',
      createdAt: new Date('2025-01-01T00:00:00.000Z'),
      roles: [{ role: 'hunter' }],
      currentLevel: {
        id: 'level-3',
        slug: 'builder',
        name: 'Builder',
        description: 'Ships things',
        iconUrl: 'https://cdn.example/l3.png',
        level: 3,
        requiredBnp: BigInt(1000),
        requiredComments: 5,
        requiredDaysActive: 3,
        requiredQuests: 1,
        requiredUpdates: 2,
        requiredProjects: 1,
        color: '#123456',
        isActive: true,
        sortOrder: 3,
      },
      levelProgress: {
        achievedAt: new Date('2026-02-01T00:00:00.000Z'),
        totalBnpEarned: BigInt(2500),
        totalComments: 3,
        totalDaysActive: 12,
        totalQuestsCompleted: 1,
        totalUpdates: 4,
        totalProjects: 2,
        lastRecalculatedAt: new Date('2026-02-19T00:00:00.000Z'),
      },
      _count: {
        authoredUpdates: 4,
        authoredComments: 3,
        ownedProjects: 2,
        followerLinks: 9,
        followingLinks: 5,
      },
    });
    prisma.update.findMany.mockResolvedValue([
      {
        id: 'u1',
        urgency: UpdateUrgency.high,
        createdAt: new Date('2026-02-20T10:00:00.000Z'),
      },
      {
        id: 'u2',
        urgency: UpdateUrgency.low,
        createdAt: new Date('2026-02-19T10:00:00.000Z'),
      },
      {
        id: 'u3',
        urgency: UpdateUrgency.high,
        createdAt: new Date('2026-02-15T10:00:00.000Z'),
      },
      {
        id: 'u4',
        urgency: UpdateUrgency.medium,
        createdAt: new Date('2026-01-10T10:00:00.000Z'),
      },
    ]);

    const result = await service.getPublicProfile('user-1');

    expect(result).not.toBeNull();
    expect(result?.trust).toEqual({
      updatesLast7d: 3,
      updatesLast30d: 3,
      highUrgencyShare30d: 66.67,
      medianHoursBetweenUpdates: 96,
      lastActiveAt: new Date('2026-02-20T10:00:00.000Z'),
    });
    expect(result?.currentLevel).toEqual({
      id: 'level-3',
      slug: 'builder',
      name: 'Builder',
      description: 'Ships things',
      iconUrl: 'https://cdn.example/l3.png',
      level: 3,
      requiredBnp: '1000',
      requiredComments: 5,
      requiredDaysActive: 3,
      requiredQuests: 1,
      requiredUpdates: 2,
      requiredProjects: 1,
      color: '#123456',
      isActive: true,
      sortOrder: 3,
    });
    expect(result?.levelProgress).toEqual({
      achievedAt: new Date('2026-02-01T00:00:00.000Z'),
      totalBnpEarned: '2500',
      totalComments: 3,
      totalDaysActive: 12,
      totalQuestsCompleted: 1,
      totalUpdates: 4,
      totalProjects: 2,
      lastRecalculatedAt: new Date('2026-02-19T00:00:00.000Z'),
    });
    expect(() => JSON.stringify(result)).not.toThrow();
  });

  it('returns null level fields on public profile when user has no level', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-2',
      displayName: 'Newbie',
      avatarUrl: null,
      createdAt: new Date('2026-01-01T00:00:00.000Z'),
      roles: [],
      currentLevel: null,
      levelProgress: null,
      _count: {
        authoredUpdates: 0,
        authoredComments: 0,
        ownedProjects: 0,
        followerLinks: 0,
        followingLinks: 0,
      },
    });
    prisma.update.findMany.mockResolvedValue([]);

    const result = await service.getPublicProfile('user-2');

    expect(result?.currentLevel).toBeNull();
    expect(result?.levelProgress).toBeNull();
  });

  it('deactivates account and records an audit event', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-1',
      isDeactivated: false,
      username: 'jazzdev',
      displayName: 'Jazz',
      avatarUrl: 'https://img.example/jazz.png',
      bio: 'Bio',
    });
    prisma.profile.update.mockResolvedValue({
      id: 'user-1',
      isDeactivated: true,
      deactivatedAt: new Date('2026-02-20T13:00:00.000Z'),
    });

    await service.deactivateAccount('user-1', 'manual review');

    expect(prisma.profile.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user-1' },
        data: expect.objectContaining({
          isDeactivated: true,
          deactivatedBy: 'user-1',
          deactivationReason: 'manual review',
          previousUsername: 'jazzdev',
        }),
      }),
    );
    expect(auditLogService.create as jest.Mock).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: 'user-1',
        action: 'account.deactivate',
      }),
    );
  });

  it('reactivates account and restores previous profile fields', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-1',
      isDeactivated: true,
      previousUsername: 'jazzdev',
      previousDisplayName: 'Jazz',
      previousAvatarUrl: 'https://img.example/jazz.png',
      previousBio: 'Bio',
    });
    prisma.profile.update.mockResolvedValue({
      id: 'user-1',
      isDeactivated: false,
      username: 'jazzdev',
      displayName: 'Jazz',
    });

    await service.reactivateAccount('user-1');

    expect(prisma.profile.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user-1' },
        data: expect.objectContaining({
          isDeactivated: false,
          username: 'jazzdev',
          previousUsername: null,
        }),
      }),
    );
    expect(auditLogService.create as jest.Mock).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: 'user-1',
        action: 'account.reactivate',
      }),
    );
  });

  it('rejects reactivation if account is not deactivated', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-1',
      isDeactivated: false,
      previousUsername: null,
      previousDisplayName: null,
      previousAvatarUrl: null,
      previousBio: null,
    });

    await expect(service.reactivateAccount('user-1')).rejects.toThrow(
      BadRequestException,
    );
  });

  it('returns only user-facing actions for profile activity feed', async () => {
    prisma.auditLog.findMany.mockResolvedValue([
      {
        id: 'log-1',
        action: 'project.follow',
        resourceType: 'project',
        resourceId: 'project-1',
        metadata: {},
        createdAt: new Date('2026-02-23T10:00:00.000Z'),
      },
    ]);

    const activity = await service.listMyActivity('user-1', {
      limit: 20,
      offset: 0,
    });

    expect(prisma.auditLog.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          actorId: 'user-1',
          action: {
            in: expect.arrayContaining([
              'project.follow',
              'project.unfollow',
              'profile.follow',
              'profile.unfollow',
            ]),
          },
        },
      }),
    );

    expect(activity).toEqual([
      expect.objectContaining({
        id: 'log-1',
        action: 'project.follow',
      }),
    ]);
  });
});
