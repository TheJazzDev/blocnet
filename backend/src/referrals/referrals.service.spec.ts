import { AuditLogService } from '../audit-log/audit-log.service';
import { ReferralsService } from './referrals.service';

describe('ReferralsService', () => {
  const prisma = {
    miningConfig: {
      upsert: jest.fn(),
    },
    profile: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      count: jest.fn(),
      findMany: jest.fn(),
    },
  };

  const runtimeFeatureFlagsService = {
    isMiningEnabled: jest.fn(),
    isReferralsEnabled: jest.fn(),
  };

  const auditLogService = {
    create: jest.fn(),
  } as unknown as AuditLogService;
  const badgesService = {
    checkReferralMilestones: jest.fn(),
  };
  const questsService = {
    checkAndCompleteByAction: jest.fn(),
  };

  let service: ReferralsService;

  beforeEach(() => {
    jest.resetAllMocks();

    runtimeFeatureFlagsService.isMiningEnabled.mockReturnValue(true);
    runtimeFeatureFlagsService.isReferralsEnabled.mockReturnValue(true);
    badgesService.checkReferralMilestones.mockResolvedValue(undefined);
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

    service = new ReferralsService(
      prisma as any,
      runtimeFeatureFlagsService as any,
      auditLogService,
      badgesService as any,
      questsService as any,
    );
  });

  it('binds referral once within bind window', async () => {
    prisma.profile.findUnique
      .mockResolvedValueOnce({
        id: 'user-1',
        createdAt: new Date(),
        referredById: null,
      })
      .mockResolvedValueOnce({
        id: 'referrer-1',
        referralCode: 'AB12CD34',
        referredById: null,
      });

    const result = await service.bind('user-1', 'ab12cd34');

    expect(prisma.profile.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user-1' },
        data: expect.objectContaining({ referredById: 'referrer-1' }),
      }),
    );
    expect(auditLogService.create).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'referral.bind' }),
    );
    expect(result).toEqual(
      expect.objectContaining({
        ok: true,
        referredById: 'referrer-1',
      }),
    );
  });

  it('fails bind when user already has referrer', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-1',
      createdAt: new Date(),
      referredById: 'existing-referrer',
    });

    await expect(service.bind('user-1', 'AB12CD34')).rejects.toThrow(
      'already been bound',
    );
  });

  it('fails self-referral', async () => {
    prisma.profile.findUnique
      .mockResolvedValueOnce({
        id: 'user-1',
        createdAt: new Date(),
        referredById: null,
      })
      .mockResolvedValueOnce({
        id: 'user-1',
        referralCode: 'AB12CD34',
        referredById: null,
      });

    await expect(service.bind('user-1', 'AB12CD34')).rejects.toThrow(
      'cannot use your own referral code',
    );
  });

  it('fails bind when window expired', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-1',
      createdAt: new Date(Date.now() - 48 * 60 * 60 * 1000),
      referredById: null,
    });

    await expect(service.bind('user-1', 'AB12CD34')).rejects.toThrow(
      'bind window has expired',
    );
  });

  it('counts active referrals using latest mining session start window', async () => {
    const now = new Date();

    prisma.profile.findUnique.mockResolvedValueOnce({
      id: 'user-1',
      createdAt: now,
      referralCode: 'ME12CODE',
      referredById: null,
      referredAt: null,
    });
    prisma.profile.count.mockResolvedValue(2);
    prisma.profile.findMany.mockResolvedValue([
      {
        miningSessions: [
          {
            startsAt: new Date(now.getTime() - 24 * 60 * 60 * 1000),
          },
        ],
      },
      {
        miningSessions: [
          {
            startsAt: new Date(now.getTime() - 10 * 24 * 60 * 60 * 1000),
          },
        ],
      },
    ]);

    const result = await service.getMe('user-1');

    expect(result.totalDirectReferrals).toBe(2);
    expect(result.activeDirectReferrals).toBe(1);
  });

  it('allows admin to bind referral after user bind window expired', async () => {
    prisma.profile.findUnique
      .mockResolvedValueOnce({
        id: 'user-2',
        email: 'user2@example.com',
        displayName: 'User Two',
        referredById: null,
      })
      .mockResolvedValueOnce({
        id: 'referrer-2',
        email: 'ref2@example.com',
        displayName: 'Referrer Two',
        referralCode: 'ZX12CV34',
        referredById: null,
      });

    const result = await service.bindByAdmin(
      'admin-1',
      '4e8aa7b2-0f97-4cd7-94dd-3cbf3d7df455',
      'zx12cv34',
    );

    expect(prisma.profile.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user-2' },
        data: expect.objectContaining({ referredById: 'referrer-2' }),
      }),
    );
    expect(auditLogService.create).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'referral.admin_bind' }),
    );
    expect(result).toEqual(
      expect.objectContaining({
        ok: true,
        source: 'admin_override',
        targetUser: expect.objectContaining({ id: 'user-2' }),
        referrer: expect.objectContaining({ id: 'referrer-2' }),
      }),
    );
  });

  it('fails admin bind when target already has a referrer', async () => {
    prisma.profile.findUnique.mockResolvedValueOnce({
      id: 'user-3',
      email: 'user3@example.com',
      displayName: 'User Three',
      referredById: 'existing-referrer',
    });

    await expect(
      service.bindByAdmin(
        'admin-1',
        'e2ea2dc6-bf55-42f0-8d5a-77f61b0c56a7',
        'AB12CD34',
      ),
    ).rejects.toThrow('already has a bound referrer');
  });

  it('allows admin to resolve target user by email', async () => {
    prisma.profile.findFirst.mockResolvedValueOnce({
      id: 'user-9',
      email: 'babsman4all@gmail.com',
      displayName: 'Babs',
      referredById: null,
    });
    prisma.profile.findUnique.mockResolvedValueOnce({
      id: 'referrer-9',
      email: 'ref9@example.com',
      displayName: 'Ref Nine',
      referralCode: 'AB12CD34',
      referredById: null,
    });

    const result = await service.bindByAdmin(
      'admin-1',
      'babsman4all@gmail.com',
      'AB12CD34',
    );

    expect(prisma.profile.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          email: {
            equals: 'babsman4all@gmail.com',
            mode: 'insensitive',
          },
        },
      }),
    );
    expect(result).toEqual(
      expect.objectContaining({
        ok: true,
        targetUser: expect.objectContaining({ id: 'user-9' }),
      }),
    );
  });
});
