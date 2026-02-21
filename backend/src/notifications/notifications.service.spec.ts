import { UpdateUrgency } from '@prisma/client';
import { NotificationsService } from './notifications.service';

describe('NotificationsService', () => {
  const prisma = {
    projectFollow: {
      findMany: jest.fn(),
    },
    notification: {
      createMany: jest.fn(),
    },
  };
  const configService = {
    get: jest.fn().mockReturnValue(true),
  };

  let service: NotificationsService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new NotificationsService(prisma as any, configService as any);
  });

  it('filters followers by mute window and min urgency', async () => {
    prisma.projectFollow.findMany.mockResolvedValue([
      {
        userId: 'low-user',
        alertMinUrgency: UpdateUrgency.low,
        mutedUntil: null,
      },
      {
        userId: 'mid-user',
        alertMinUrgency: UpdateUrgency.medium,
        mutedUntil: null,
      },
      {
        userId: 'high-only-user',
        alertMinUrgency: UpdateUrgency.high,
        mutedUntil: null,
      },
      {
        userId: 'muted-user',
        alertMinUrgency: UpdateUrgency.low,
        mutedUntil: new Date(Date.now() + 60 * 60 * 1000),
      },
    ]);

    const eligible = await service.resolveEligibleFollowerUserIds({
      projectId: 'p1',
      urgency: UpdateUrgency.medium,
    });

    expect(eligible).toEqual(['low-user', 'mid-user']);
  });

  it('creates notifications only for eligible followers', async () => {
    prisma.projectFollow.findMany.mockResolvedValue([
      {
        userId: 'u1',
        alertMinUrgency: UpdateUrgency.low,
        mutedUntil: null,
      },
      {
        userId: 'u2',
        alertMinUrgency: UpdateUrgency.high,
        mutedUntil: null,
      },
    ]);
    prisma.notification.createMany.mockResolvedValue({ count: 1 });

    const result = await service.createForProjectFollowers({
      projectId: 'p1',
      updateId: 'u1',
      title: 'New update',
      body: 'Body',
      urgency: UpdateUrgency.medium,
    });

    expect(prisma.notification.createMany).toHaveBeenCalledWith(
      expect.objectContaining({
        data: [
          expect.objectContaining({
            userId: 'u1',
            projectId: 'p1',
            updateId: 'u1',
          }),
        ],
      }),
    );
    expect(result).toEqual({ insertedCount: 1, userIds: ['u1'] });
  });
});
