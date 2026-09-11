import { BadRequestException } from '@nestjs/common';
import { AuditLogService } from '../audit-log/audit-log.service';
import { NotificationsService } from '../notifications/notifications.service';
import { TipsService } from './tips.service';

function currencyRow(code: string, overrides: Record<string, unknown> = {}) {
  return {
    code,
    name: code,
    symbol: code,
    decimals: 3,
    kind: 'points',
    isEnabled: true,
    isActiveTippingCurrency: code === 'BNP',
    createdAt: new Date('2026-01-01T00:00:00Z'),
    updatedAt: new Date('2026-01-01T00:00:00Z'),
    feeConfig: null,
    accounts: [],
    ...overrides,
  };
}

describe('TipsService (admin settings, retired currencies)', () => {
  const prisma = {
    $transaction: jest.fn(),
    tipCurrency: {
      upsert: jest.fn(),
      count: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
    },
    tipFeeConfig: {
      upsert: jest.fn(),
    },
    tipAccount: {
      upsert: jest.fn(),
    },
  };

  const auditLogService = {
    create: jest.fn(),
  } as unknown as AuditLogService;

  const notificationsService = {
    notifyMany: jest.fn(),
  } as unknown as NotificationsService;

  let service: TipsService;

  beforeEach(() => {
    jest.clearAllMocks();
    // Bootstrap runs inside a transaction; hand the callback the same mock.
    prisma.$transaction.mockImplementation(
      async (callback: (tx: typeof prisma) => Promise<unknown>) =>
        callback(prisma),
    );
    prisma.tipCurrency.upsert.mockResolvedValue({});
    prisma.tipCurrency.count.mockResolvedValue(1);
    prisma.tipFeeConfig.upsert.mockResolvedValue({});
    prisma.tipAccount.upsert.mockResolvedValue({});
    prisma.tipCurrency.findMany.mockResolvedValue([]);

    service = new TipsService(
      prisma as any,
      auditLogService,
      notificationsService,
    );
  });

  describe('getAdminSettings', () => {
    it('excludes retired codes at the query level', async () => {
      prisma.tipCurrency.findMany.mockResolvedValue([
        currencyRow('BNP'),
        currencyRow('BNT', { kind: 'token', decimals: 18 }),
      ]);

      const result = await service.getAdminSettings();

      expect(prisma.tipCurrency.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { code: { notIn: ['MCR'] } },
        }),
      );
      expect(result.activeCurrencyCode).toBe('BNP');
      expect(result.currencies.map((row) => row.code)).toEqual(['BNP', 'BNT']);
    });

    it('never returns MCR even if a stray row slips past the query filter', async () => {
      prisma.tipCurrency.findMany.mockResolvedValue([
        currencyRow('BNP'),
        currencyRow('MCR', { name: 'Mine Credits' }),
      ]);

      const result = await service.getAdminSettings();

      expect(result.currencies.map((row) => row.code)).toEqual(['BNP']);
      expect(result.currencies.some((row) => row.code === 'MCR')).toBe(false);
    });
  });

  describe('updateCurrencySettings', () => {
    it('rejects enabling the retired MCR currency', async () => {
      await expect(
        service.updateCurrencySettings('actor-1', 'MCR', { isEnabled: true }),
      ).rejects.toBeInstanceOf(BadRequestException);

      expect(prisma.tipCurrency.findUnique).not.toHaveBeenCalled();
      expect(prisma.tipCurrency.update).not.toHaveBeenCalled();
      expect(auditLogService.create).not.toHaveBeenCalled();
    });

    it('normalises the code before checking (lower case, padded)', async () => {
      await expect(
        service.updateCurrencySettings('actor-1', ' mcr ', { name: 'x' }),
      ).rejects.toBeInstanceOf(BadRequestException);

      expect(prisma.tipCurrency.findUnique).not.toHaveBeenCalled();
    });

    it('rejects a payload that tries to (re)create MCR through the code field', async () => {
      await expect(
        service.updateCurrencySettings('actor-1', 'BNP', { code: 'MCR' }),
      ).rejects.toBeInstanceOf(BadRequestException);

      expect(prisma.tipCurrency.findUnique).not.toHaveBeenCalled();
    });

    it('still lets live currencies through to the lookup', async () => {
      prisma.tipCurrency.findUnique.mockResolvedValue(null);

      await expect(
        service.updateCurrencySettings('actor-1', 'BNP', { name: 'Points' }),
      ).rejects.toThrow('Tip currency not found');

      expect(prisma.tipCurrency.findUnique).toHaveBeenCalledWith(
        expect.objectContaining({ where: { code: 'BNP' } }),
      );
    });
  });

  describe('setActiveCurrency', () => {
    it('rejects activating the retired MCR currency', async () => {
      await expect(
        service.setActiveCurrency('actor-1', 'MCR'),
      ).rejects.toBeInstanceOf(BadRequestException);

      expect(prisma.tipCurrency.findUnique).not.toHaveBeenCalled();
      expect(prisma.tipCurrency.updateMany).not.toHaveBeenCalled();
      expect(auditLogService.create).not.toHaveBeenCalled();
    });
  });
});
