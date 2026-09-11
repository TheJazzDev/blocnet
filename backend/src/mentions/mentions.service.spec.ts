import { NotificationsService } from '../notifications/notifications.service';
import { MentionsService } from './mentions.service';

describe('MentionsService', () => {
  const prisma = {
    profile: {
      findMany: jest.fn(),
    },
  };

  const notificationsService = {
    create: jest.fn(),
  } as unknown as NotificationsService;

  let service: MentionsService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new MentionsService(prisma as any, notificationsService);
  });

  it('includes the canonical currentLevel on user search results', async () => {
    prisma.profile.findMany.mockResolvedValue([
      {
        id: 'user-1',
        email: 'one@example.com',
        username: 'One_User',
        displayName: 'One',
        avatarUrl: null,
        currentLevel: {
          id: 'level-1',
          slug: 'newcomer',
          name: 'Newcomer',
          description: 'Just joined',
          iconUrl: 'https://cdn.example/l1.png',
          level: 1,
          requiredBnp: BigInt(0),
          requiredComments: 0,
          requiredDaysActive: 0,
          requiredQuests: 0,
          requiredUpdates: 0,
          requiredProjects: 0,
          color: null,
          isActive: true,
          sortOrder: 1,
        },
      },
      {
        id: 'user-2',
        email: 'two@example.com',
        username: null,
        displayName: 'Two',
        avatarUrl: null,
        currentLevel: null,
      },
    ]);

    const result = await service.searchUsers('on', 10);

    expect(prisma.profile.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        select: expect.objectContaining({
          currentLevel: expect.objectContaining({ select: expect.any(Object) }),
        }),
      }),
    );
    expect(result).toEqual([
      {
        id: 'user-1',
        username: 'one_user',
        displayName: 'One',
        avatarUrl: null,
        currentLevel: expect.objectContaining({
          id: 'level-1',
          slug: 'newcomer',
          requiredBnp: '0',
        }),
      },
      {
        id: 'user-2',
        username: 'two',
        displayName: 'Two',
        avatarUrl: null,
        currentLevel: null,
      },
    ]);
    expect(() => JSON.stringify(result)).not.toThrow();
  });
});
