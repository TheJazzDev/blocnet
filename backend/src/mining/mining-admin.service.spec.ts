import { AuditLogService } from '../audit-log/audit-log.service';
import { MiningAdminService } from './mining-admin.service';
import { MiningConfigService } from './mining-config.service';

describe('MiningAdminService', () => {
  const prisma = {
    miningSession: {
      findMany: jest.fn(),
      count: jest.fn(),
      aggregate: jest.fn(),
    },
    profile: {
      count: jest.fn(),
    },
    miningHourlyCheckpoint: {
      aggregate: jest.fn(),
      findMany: jest.fn(),
    },
  };

  const auditLogService = {
    create: jest.fn(),
  } as unknown as AuditLogService;

  const miningConfigService = {
    getEffectiveConfig: jest.fn(),
  } as unknown as MiningConfigService;

  let service: MiningAdminService;

  beforeEach(() => {
    jest.clearAllMocks();
    (miningConfigService.getEffectiveConfig as jest.Mock).mockResolvedValue({
      referralsEnabled: false,
      activeReferralWindowHours: 24,
    });
    prisma.miningSession.findMany.mockResolvedValue([{ userId: 'u1' }]);
    prisma.miningSession.count.mockResolvedValue(3);
    prisma.miningSession.aggregate.mockResolvedValue({
      _avg: { boostBpsSnapshot: 250.4 },
    });
    prisma.profile.count.mockResolvedValueOnce(40).mockResolvedValueOnce(10);
    prisma.miningHourlyCheckpoint.aggregate
      .mockResolvedValueOnce({ _sum: { points: 1200 } })
      .mockResolvedValueOnce({ _sum: { points: 450 } });
    prisma.miningHourlyCheckpoint.findMany.mockResolvedValue([
      { userId: 'u1' },
      { userId: 'u2' },
    ]);

    service = new MiningAdminService(
      prisma as any,
      auditLogService,
      miningConfigService,
    );
  });

  it('reports lifetime totals under the BNP keys', async () => {
    const metrics = await service.getAdminMetrics();

    expect(metrics).toMatchObject({
      lifetimeMinedBnp: 1200,
      lifetimeClaimedBnp: 450,
      lifetimeUnclaimedBnp: 750,
      totalMiners: 2,
      dauMiners: 1,
      averageBoostBps: 250,
    });
  });

  it('keeps the deprecated *Mcr aliases equal to the BNP values', async () => {
    const metrics = await service.getAdminMetrics();

    expect(metrics.lifetimeMinedMcr).toBe(metrics.lifetimeMinedBnp);
    expect(metrics.lifetimeClaimedMcr).toBe(metrics.lifetimeClaimedBnp);
    expect(metrics.lifetimeUnclaimedMcr).toBe(metrics.lifetimeUnclaimedBnp);
  });
});
