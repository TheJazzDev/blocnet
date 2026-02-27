/* eslint-disable @typescript-eslint/no-unsafe-argument */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/unbound-method */
import { ForbiddenException } from '@nestjs/common';
import { AppRole } from '../common/enums/role.enum';
import { NotificationEventsService } from '../notifications/notification-events.service';
import { AuditLogService } from './audit-log.service';

describe('AuditLogService', () => {
  const prisma = {
    auditLog: {
      create: jest.fn(),
      findMany: jest.fn(),
    },
  };

  const notificationEventsService = {
    emitForAudit: jest.fn(),
  } as unknown as NotificationEventsService;

  let service: AuditLogService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new AuditLogService(prisma as any, notificationEventsService);
  });

  it('creates audit entry and emits notification events', async () => {
    prisma.auditLog.create.mockResolvedValue({
      id: 'log-1',
      action: 'project.create',
      actorId: 'user-1',
      resourceId: 'project-1',
      metadata: { foo: 'bar' },
    });

    await service.create({
      actorId: 'user-1',
      action: 'project.create',
      resourceType: 'project',
      resourceId: 'project-1',
      metadata: { foo: 'bar' },
    });

    expect(prisma.auditLog.create).toHaveBeenCalled();
    expect(notificationEventsService.emitForAudit).toHaveBeenCalledWith({
      action: 'project.create',
      actorId: 'user-1',
      resourceId: 'project-1',
      metadata: { foo: 'bar' },
    });
  });

  it('returns all logs for owner role', async () => {
    prisma.auditLog.findMany.mockResolvedValue([]);

    await service.listForUser(
      {
        id: 'owner-1',
        email: 'owner@test.dev',
        roles: [AppRole.OWNER],
      },
      20,
      5,
    );

    expect(prisma.auditLog.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        orderBy: { createdAt: 'desc' },
        skip: 5,
        take: 20,
      }),
    );
    const call = prisma.auditLog.findMany.mock.calls[0]?.[0];
    expect(call).not.toHaveProperty('where');
  });

  it('hides owner-governance events from admin role', async () => {
    prisma.auditLog.findMany.mockResolvedValue([]);

    await service.listForUser({
      id: 'admin-1',
      email: 'admin@test.dev',
      roles: [AppRole.ADMIN],
    });

    expect(prisma.auditLog.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          NOT: expect.objectContaining({
            action: expect.objectContaining({
              in: expect.arrayContaining([
                'role.promote.owner',
                'role.demote.owner',
                'admin.user.hard_delete',
              ]),
            }),
          }),
        }),
      }),
    );
  });

  it('restricts moderator view to moderation-focused actions', async () => {
    prisma.auditLog.findMany.mockResolvedValue([]);

    await service.listForUser({
      id: 'mod-1',
      email: 'mod@test.dev',
      roles: [AppRole.MODERATOR],
    });

    expect(prisma.auditLog.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          OR: expect.arrayContaining([
            expect.objectContaining({
              action: expect.objectContaining({
                in: expect.arrayContaining(['settings.runtime_features.view']),
              }),
            }),
            expect.objectContaining({
              action: expect.objectContaining({
                startsWith: 'project.moderate.',
              }),
            }),
          ]),
        }),
      }),
    );
  });

  it('throws for users without governance role', async () => {
    await expect(
      service.listForUser({
        id: 'user-1',
        email: 'user@test.dev',
        roles: [AppRole.USER],
      }),
    ).rejects.toThrow(ForbiddenException);
  });
});
