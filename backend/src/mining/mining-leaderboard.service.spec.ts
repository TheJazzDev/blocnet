import { MiningCalculatorService } from './mining-calculator.service';
import { MiningLeaderboardService } from './mining-leaderboard.service';

describe('MiningLeaderboardService', () => {
  const prisma = {
    profile: {
      findMany: jest.fn(),
      count: jest.fn(),
    },
    miningHourlyCheckpoint: {
      groupBy: jest.fn(),
    },
  };

  const miningCalculator = {
    computeProgressPct: jest.fn().mockReturnValue(50),
  } as unknown as MiningCalculatorService;

  let service: MiningLeaderboardService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new MiningLeaderboardService(prisma as any, miningCalculator);
  });

  it('includes the canonical currentLevel on each leaderboard row', async () => {
    prisma.profile.findMany.mockResolvedValue([
      {
        id: 'user-1',
        email: 'one@example.com',
        username: 'one',
        displayName: 'One',
        avatarUrl: null,
        miningClaimedPoints: BigInt(500),
        primaryBadge: null,
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
        miningSessions: [],
      },
      {
        id: 'user-2',
        email: 'two@example.com',
        username: 'two',
        displayName: 'Two',
        avatarUrl: null,
        miningClaimedPoints: BigInt(100),
        primaryBadge: null,
        currentLevel: null,
        miningSessions: [],
      },
    ]);
    prisma.profile.count.mockResolvedValue(2);
    prisma.miningHourlyCheckpoint.groupBy.mockResolvedValue([]);

    const result = await service.getLeaderboard();

    expect(prisma.profile.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        select: expect.objectContaining({
          currentLevel: expect.objectContaining({ select: expect.any(Object) }),
        }),
      }),
    );
    expect(result.data[0]).toMatchObject({
      rank: 1,
      userId: 'user-1',
      claimedTotalPoints: '500',
      currentLevel: {
        id: 'level-1',
        slug: 'newcomer',
        level: 1,
        requiredBnp: '0',
      },
    });
    expect(result.data[1].currentLevel).toBeNull();
    expect(() => JSON.stringify(result)).not.toThrow();
  });
});
