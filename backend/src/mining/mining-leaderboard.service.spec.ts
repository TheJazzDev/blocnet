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

  const miningConfigService = {
    getEffectiveConfig: jest.fn().mockResolvedValue({
      enabled: true,
      referralsEnabled: true,
      cycleHours: 24,
      basePointsPerCycle: 120,
      perActiveReferralBoostBps: 500,
      maxBoostBps: 10000,
      activeReferralWindowHours: 168,
      referralBindWindowHours: 24,
      claimWindowHours: 48,
    }),
  };

  let service: MiningLeaderboardService;

  beforeEach(() => {
    jest.clearAllMocks();
    miningConfigService.getEffectiveConfig.mockResolvedValue({
      enabled: true,
      referralsEnabled: true,
      cycleHours: 24,
      basePointsPerCycle: 120,
      perActiveReferralBoostBps: 500,
      maxBoostBps: 10000,
      activeReferralWindowHours: 168,
      referralBindWindowHours: 24,
      claimWindowHours: 48,
    });
    service = new MiningLeaderboardService(
      prisma as any,
      miningCalculator,
      miningConfigService as any,
    );
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
  it('does not badge a cycle past its claim window as claimable', async () => {
    const now = Date.now();
    const hour = 60 * 60 * 1000;
    prisma.profile.findMany.mockResolvedValue([
      {
        id: 'stuck-user',
        email: 'stuck@example.com',
        username: 'stuck',
        displayName: 'Stuck',
        avatarUrl: null,
        miningClaimedPoints: BigInt(120),
        primaryBadge: null,
        currentLevel: null,
        miningSessions: [
          {
            id: 'session-stuck',
            startsAt: new Date(now - 100 * hour),
            endsAt: new Date(now - 76 * hour),
            boostBpsSnapshot: 0,
            activeReferralsSnapshot: 0,
          },
        ],
      },
      {
        id: 'fresh-user',
        email: 'fresh@example.com',
        username: 'fresh',
        displayName: 'Fresh',
        avatarUrl: null,
        miningClaimedPoints: BigInt(60),
        primaryBadge: null,
        currentLevel: null,
        miningSessions: [
          {
            id: 'session-fresh',
            startsAt: new Date(now - 30 * hour),
            endsAt: new Date(now - 6 * hour),
            boostBpsSnapshot: 0,
            activeReferralsSnapshot: 0,
          },
        ],
      },
    ]);
    prisma.profile.count.mockResolvedValue(2);
    prisma.miningHourlyCheckpoint.groupBy.mockResolvedValue([]);

    const result = await service.getLeaderboard();

    expect(result.data[0]).toMatchObject({
      userId: 'stuck-user',
      sessionStatus: 'idle',
      sessionEndsAt: null,
      sessionProgressPct: 0,
    });
    expect(result.data[1]).toMatchObject({
      userId: 'fresh-user',
      sessionStatus: 'claimable',
    });
    expect(prisma.miningHourlyCheckpoint.groupBy).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ claimedAt: null, expiredAt: null }),
      }),
    );
  });
});
