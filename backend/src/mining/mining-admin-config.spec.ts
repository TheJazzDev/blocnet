import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { AuditLogService } from '../audit-log/audit-log.service';
import { UpdateMiningConfigDto } from './dto/update-mining-config.dto';
import { MiningAdminService } from './mining-admin.service';
import { MiningConfigService } from './mining-config.service';

/**
 * F-47: the admin config round-trip. GET and PATCH return the raw stored row
 * plus the runtime flags separately, so a console save can never persist
 * flag-ANDed `enabled` / `referralsEnabled` values.
 */
describe('Mining admin config (F-47)', () => {
  const storedRow = {
    id: 'default',
    enabled: true,
    referralsEnabled: true,
    cycleHours: 24,
    basePointsPerCycle: 120,
    perActiveReferralBoostBps: 500,
    maxBoostBps: 10000,
    activeReferralWindowHours: 168,
    referralBindWindowHours: 24,
    claimWindowHours: 48,
    updatedAt: new Date('2026-09-16T10:00:00.000Z'),
  };

  const prisma = { miningConfig: { upsert: jest.fn() } };
  const flags = {
    isMiningEnabled: jest.fn(),
    isReferralsEnabled: jest.fn(),
  };
  const auditLogService = { create: jest.fn() };
  let service: MiningAdminService;
  let configService: MiningConfigService;

  beforeEach(() => {
    jest.resetAllMocks();
    // Both runtime flags OFF: the raw row must still come back as stored.
    flags.isMiningEnabled.mockReturnValue(false);
    flags.isReferralsEnabled.mockReturnValue(false);
    auditLogService.create.mockResolvedValue({});
    configService = new MiningConfigService(prisma as never, flags as never);
    service = new MiningAdminService(
      prisma as never,
      auditLogService as unknown as AuditLogService,
      configService,
    );
  });

  const expectedShape = (row: typeof storedRow) => ({
    enabled: row.enabled,
    referralsEnabled: row.referralsEnabled,
    cycleHours: row.cycleHours,
    basePointsPerCycle: row.basePointsPerCycle,
    perActiveReferralBoostBps: row.perActiveReferralBoostBps,
    maxBoostBps: row.maxBoostBps,
    activeReferralWindowHours: row.activeReferralWindowHours,
    referralBindWindowHours: row.referralBindWindowHours,
    claimWindowHours: row.claimWindowHours,
    runtimeFlags: { miningEnabled: false, referralsEnabled: false },
    updatedAt: row.updatedAt.toISOString(),
  });

  it('GET returns the raw stored row plus runtime flags, and nothing else', async () => {
    prisma.miningConfig.upsert.mockResolvedValue(storedRow);

    const config = await service.getAdminConfig();

    expect(config).toStrictEqual(expectedShape(storedRow));
  });

  it('PATCH persists only the patch and returns the same shape', async () => {
    const updatedRow = {
      ...storedRow,
      claimWindowHours: 72,
      updatedAt: new Date('2026-09-16T11:00:00.000Z'),
    };
    prisma.miningConfig.upsert
      .mockResolvedValueOnce(storedRow)
      .mockResolvedValueOnce(updatedRow);

    const config = await service.updateAdminConfig('admin-1', {
      claimWindowHours: 72,
    });

    expect(prisma.miningConfig.upsert).toHaveBeenLastCalledWith(
      expect.objectContaining({ update: { claimWindowHours: 72 } }),
    );
    expect(config).toStrictEqual(expectedShape(updatedRow));
  });

  it('PATCH audits the action with a before/after diff of the patched fields (F-65)', async () => {
    const updatedRow = { ...storedRow, claimWindowHours: 72, enabled: false };
    prisma.miningConfig.upsert
      .mockResolvedValueOnce(storedRow)
      .mockResolvedValueOnce(updatedRow);

    await service.updateAdminConfig('admin-1', {
      claimWindowHours: 72,
      enabled: false,
    });

    expect(auditLogService.create).toHaveBeenCalledWith({
      actorId: 'admin-1',
      action: 'admin.mining.config.update',
      resourceType: 'mining_config',
      resourceId: 'default',
      metadata: {
        claimWindowHours: 72,
        enabled: false,
        before: { claimWindowHours: 48, enabled: true },
        after: { claimWindowHours: 72, enabled: false },
      },
    });
  });

  it('the user-facing effective config still ANDs the runtime flags', async () => {
    prisma.miningConfig.upsert.mockResolvedValue(storedRow);

    const effective = await configService.getEffectiveConfig();

    expect(effective.enabled).toBe(false);
    expect(effective.referralsEnabled).toBe(false);
    expect(effective).not.toHaveProperty('runtimeFlags');
  });

  describe('UpdateMiningConfigDto', () => {
    async function errorsFor(body: Record<string, unknown>) {
      const dto = plainToInstance(UpdateMiningConfigDto, body);
      return validate(dto, {
        whitelist: true,
        forbidNonWhitelisted: true,
      });
    }

    it('accepts every editable field the GET returns, including claimWindowHours', async () => {
      const { runtimeFlags, updatedAt, ...editable } = expectedShape(storedRow);
      void runtimeFlags;
      void updatedAt;

      await expect(errorsFor(editable)).resolves.toHaveLength(0);
    });

    it.each([0, 169, 1.5])('rejects claimWindowHours=%p', async (value) => {
      const errors = await errorsFor({ claimWindowHours: value });

      expect(errors.map((error) => error.property)).toEqual([
        'claimWindowHours',
      ]);
    });

    it.each([1, 168])('accepts claimWindowHours=%p', async (value) => {
      await expect(
        errorsFor({ claimWindowHours: value }),
      ).resolves.toHaveLength(0);
    });
  });
});
