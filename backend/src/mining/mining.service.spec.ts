import { AuditLogService } from '../audit-log/audit-log.service';
import { MiningService } from './mining.service';

function checkpointIndexes(count: number) {
  return Array.from({ length: count }, (_, index) => ({ hourIndex: index + 1 }));
}

describe('MiningService', () => {
  const prisma = {
    profile: {
      findUnique: jest.fn(),
      update: jest.fn(),
      count: jest.fn(),
    },
    miningConfig: {
      upsert: jest.fn(),
    },
    miningSession: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      aggregate: jest.fn(),
      count: jest.fn(),
      updateMany: jest.fn(),
    },
    miningPointLedger: {
      create: jest.fn(),
      findMany: jest.fn(),
    },
    tipCurrency: {
      upsert: jest.fn(),
    },
    tipAccount: {
      upsert: jest.fn(),
    },
    miningHourlyCheckpoint: {
      findMany: jest.fn(),
      create: jest.fn(),
      aggregate: jest.fn(),
      count: jest.fn(),
      updateMany: jest.fn(),
    },
    $transaction: jest.fn(),
  };

  const runtimeFeatureFlagsService = {
    isMiningEnabled: jest.fn(),
    isReferralsEnabled: jest.fn(),
  };

  const auditLogService = {
    create: jest.fn(),
  } as unknown as AuditLogService;
  const badgesService = {
    checkMiningMilestones: jest.fn(),
  };
  const questsService = {
    checkAndCompleteByAction: jest.fn(),
  };

  let service: MiningService;

  beforeEach(() => {
    jest.resetAllMocks();

    runtimeFeatureFlagsService.isMiningEnabled.mockReturnValue(true);
    runtimeFeatureFlagsService.isReferralsEnabled.mockReturnValue(true);
    badgesService.checkMiningMilestones.mockResolvedValue(undefined);
    questsService.checkAndCompleteByAction.mockResolvedValue(undefined);

    prisma.miningConfig.upsert.mockResolvedValue({
      id: 'default',
      enabled: true,
      referralsEnabled: true,
      cycleHours: 24,
      basePointsPerCycle: 120,
      perActiveReferralBoostBps: 500,
      maxBoostBps: 10000,
      activeReferralWindowHours: 168,
      referralBindWindowHours: 24,
      updatedAt: new Date('2026-02-21T00:00:00.000Z'),
    });

    prisma.profile.count.mockResolvedValue(0);
    prisma.miningSession.create.mockResolvedValue({
      id: 'session-next',
      startsAt: new Date('2026-02-22T00:00:00.000Z'),
      endsAt: new Date('2026-02-23T00:00:00.000Z'),
      claimedAt: null,
      basePointsPerCycle: 120,
      effectivePointsPerCycle: 120,
      boostBpsSnapshot: 0,
      activeReferralsSnapshot: 0,
    });
    prisma.miningHourlyCheckpoint.findMany.mockResolvedValue(checkpointIndexes(24));
    prisma.miningHourlyCheckpoint.create.mockResolvedValue({});
    prisma.miningHourlyCheckpoint.aggregate.mockResolvedValue({
      _sum: { points: 0 },
      _max: { hourIndex: null },
    });
    prisma.miningHourlyCheckpoint.count.mockResolvedValue(0);
    prisma.miningHourlyCheckpoint.updateMany.mockResolvedValue({ count: 0 });
    prisma.miningPointLedger.findMany.mockResolvedValue([]);
    prisma.tipCurrency.upsert.mockResolvedValue({});
    prisma.tipAccount.upsert.mockResolvedValue({});

    prisma.$transaction.mockImplementation(async (callback: any) =>
      callback({
        miningSession: {
          updateMany: prisma.miningSession.updateMany,
        },
        miningPointLedger: {
          create: prisma.miningPointLedger.create,
        },
        miningHourlyCheckpoint: {
          updateMany: prisma.miningHourlyCheckpoint.updateMany,
        },
        profile: {
          update: prisma.profile.update,
        },
        tipCurrency: {
          upsert: prisma.tipCurrency.upsert,
        },
        tipAccount: {
          upsert: prisma.tipAccount.upsert,
        },
      }),
    );

    service = new MiningService(
      prisma as any,
      runtimeFeatureFlagsService as any,
      auditLogService,
      badgesService as any,
      questsService as any,
    );
  });

  it('returns existing running session when start is called during active cycle', async () => {
    const now = new Date();
    prisma.profile.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.miningSession.findMany.mockResolvedValue([
      {
        id: 'session-1',
        startsAt: new Date(now.getTime() - 2 * 60 * 60 * 1000),
        endsAt: new Date(now.getTime() + 2 * 60 * 60 * 1000),
        claimedAt: null,
        basePointsPerCycle: 120,
        effectivePointsPerCycle: 120,
        boostBpsSnapshot: 0,
        activeReferralsSnapshot: 0,
      },
    ]);
    prisma.miningHourlyCheckpoint.findMany.mockResolvedValue(checkpointIndexes(2));
    prisma.miningHourlyCheckpoint.aggregate.mockResolvedValue({
      _sum: { points: 10 },
      _max: { hourIndex: 2 },
    });

    const result = await service.start('user-1');

    expect(result.status).toBe('running');
    expect(prisma.miningSession.create).not.toHaveBeenCalled();
  });

  it('throws claim_required when ended unclaimed session exists', async () => {
    const now = new Date();
    prisma.profile.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.miningSession.findMany.mockResolvedValue([
      {
        id: 'session-1',
        startsAt: new Date(now.getTime() - 26 * 60 * 60 * 1000),
        endsAt: new Date(now.getTime() - 2 * 60 * 60 * 1000),
        claimedAt: null,
        basePointsPerCycle: 120,
        effectivePointsPerCycle: 120,
        boostBpsSnapshot: 0,
        activeReferralsSnapshot: 0,
      },
    ]);

    await expect(service.start('user-1')).rejects.toThrow(
      'Claim the previous mining cycle before starting a new one',
    );
  });

  it('claims completed cycle using hourly checkpoint sum and updates balances', async () => {
    const now = new Date();
    const claimableSession = {
      id: 'session-1',
      startsAt: new Date(now.getTime() - 26 * 60 * 60 * 1000),
      endsAt: new Date(now.getTime() - 2 * 60 * 60 * 1000),
      claimedAt: null,
      basePointsPerCycle: 120,
      effectivePointsPerCycle: 120,
      boostBpsSnapshot: 5000,
      activeReferralsSnapshot: 10,
    };
    prisma.miningSession.findMany
      .mockResolvedValueOnce([claimableSession])
      .mockResolvedValueOnce([claimableSession])
      .mockResolvedValueOnce([]);

    prisma.miningSession.updateMany.mockResolvedValue({ count: 1 });
    prisma.miningHourlyCheckpoint.count.mockResolvedValue(24);
    prisma.miningHourlyCheckpoint.aggregate
      .mockResolvedValueOnce({
        _sum: { points: 180 },
        _max: { hourIndex: 24 },
      })
      .mockResolvedValueOnce({
        _sum: { points: 0 },
        _max: { hourIndex: null },
      });

    prisma.profile.findUnique.mockResolvedValue({ miningClaimedPoints: 180n });

    const result = await service.claim('user-1');

    expect(prisma.miningSession.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ id: 'session-1', claimedAt: null }),
      }),
    );
    expect(prisma.miningHourlyCheckpoint.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ sessionId: 'session-1', claimedAt: null }),
      }),
    );
    expect(prisma.miningPointLedger.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          source: 'cycle_claim',
          points: 180,
        }),
      }),
    );
    expect(prisma.profile.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          miningClaimedPoints: { increment: 180n },
        }),
      }),
    );
    expect(auditLogService.create).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: 'user-1',
        action: 'mining.claim',
      }),
    );
    expect(result).toEqual(
      expect.objectContaining({
        ok: true,
        claimedPoints: 180,
      }),
    );
    expect(prisma.miningSession.create).toHaveBeenCalled();
  });
});
