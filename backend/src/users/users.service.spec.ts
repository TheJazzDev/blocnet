import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppRole } from '../common/enums/role.enum';
import { AuditLogService } from '../audit-log/audit-log.service';
import { UpdateUrgency } from '@prisma/client';
import { UsersService } from './users.service';

describe('UsersService', () => {
  const txProfileUpdate = jest.fn();
  const txUserRoleUpsert = jest.fn();

  const prisma = {
    profile: {
      findUnique: jest.fn(),
      delete: jest.fn(),
    },
    auditLog: {
      findMany: jest.fn(),
    },
    update: {
      findMany: jest.fn(),
    },
    project: {
      count: jest.fn(),
    },
    userRole: {
      count: jest.fn(),
      findFirst: jest.fn(),
    },
    $transaction: jest.fn(),
  };

  const configService = {
    get: jest.fn(),
  } as unknown as ConfigService;

  const auditLogService = {
    create: jest.fn(),
  } as unknown as AuditLogService;

  let service: UsersService;

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.$transaction.mockImplementation(
      async (
        callback: (tx: {
          profile: { update: jest.Mock };
          userRole: { upsert: jest.Mock };
        }) => Promise<unknown>,
      ) =>
        callback({
          profile: { update: txProfileUpdate },
          userRole: { upsert: txUserRoleUpsert },
        }),
    );
    service = new UsersService(prisma as any, configService, auditLogService);
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
  });

  it('reactivates a deactivated user and ensures user role exists', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: 'target-1',
      isDeactivated: true,
      roles: [],
    });

    const result = await service.reactivateUserByOwner(
      {
        id: 'owner-1',
        email: 'owner@blocnet.test',
        roles: [AppRole.OWNER],
      },
      'target-1',
      { reason: 'review complete' },
    );

    expect(txProfileUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'target-1' },
        data: expect.objectContaining({
          isDeactivated: false,
          deactivatedAt: null,
          deactivatedBy: null,
          deactivationReason: null,
        }),
      }),
    );
    expect(txUserRoleUpsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          userId_role: {
            userId: 'target-1',
            role: 'user',
          },
        },
      }),
    );
    expect(auditLogService.create).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: 'owner-1',
        action: 'admin.user.reactivate',
      }),
    );
    expect(result).toEqual(
      expect.objectContaining({
        reactivated: true,
        userId: 'target-1',
      }),
    );
  });

  it('rejects reactivation when actor is not owner', async () => {
    await expect(
      service.reactivateUserByOwner(
        {
          id: 'admin-1',
          email: 'admin@blocnet.test',
          roles: [AppRole.ADMIN],
        },
        'target-1',
        {},
      ),
    ).rejects.toThrow(ForbiddenException);
  });

  it('hard deletes deactivated user for owner actor', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: 'target-1',
      isDeactivated: true,
      roles: [],
    });
    prisma.project.count.mockResolvedValue(0);
    prisma.profile.delete.mockResolvedValue({ id: 'target-1' });

    const result = await service.hardDeleteUserByOwner(
      {
        id: 'owner-1',
        email: 'owner@blocnet.test',
        roles: [AppRole.OWNER],
      },
      'target-1',
      { reason: 'gdpr request' },
    );

    expect(prisma.profile.delete).toHaveBeenCalledWith({
      where: { id: 'target-1' },
    });
    expect(auditLogService.create).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: 'owner-1',
        action: 'admin.user.hard_delete',
      }),
    );
    expect(result).toEqual(
      expect.objectContaining({
        hardDeleted: true,
        userId: 'target-1',
      }),
    );
  });

  it('requires deactivation before hard delete', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: 'target-1',
      isDeactivated: false,
      roles: [],
    });

    await expect(
      service.hardDeleteUserByOwner(
        {
          id: 'owner-1',
          email: 'owner@blocnet.test',
          roles: [AppRole.OWNER],
        },
        'target-1',
        {},
      ),
    ).rejects.toThrow(BadRequestException);
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

    const result = await service.listMyActivity('user-1', {
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

    expect(result).toEqual([
      expect.objectContaining({
        id: 'log-1',
        action: 'project.follow',
      }),
    ]);
  });
});
