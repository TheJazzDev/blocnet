import { TipTransactionType } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { NotificationsService } from '../notifications/notifications.service';
import { TipBootstrapService } from './tip-bootstrap';
import { TipsService } from './tips.service';

const USER = '11111111-1111-4111-8111-111111111111';

const bnp = {
  code: 'BNP',
  name: 'Blocnet Points',
  symbol: 'BNP',
  decimals: 3,
  kind: 'points',
  isEnabled: true,
  isActiveTippingCurrency: true,
  feeConfig: null,
};

/**
 * BNP transfers share the TipTransaction table with tips. These specs pin
 * that the member-facing tip surfaces only ever read `type: tip`.
 */
describe('TipsService (transfers are not tips)', () => {
  const prisma = {
    tipCurrency: { findFirst: jest.fn() },
    tipAccount: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
    tipTransaction: {
      groupBy: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
    },
    profile: { findUnique: jest.fn() },
  };
  const bootstrap = { ensure: jest.fn() };
  let service: TipsService;

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.tipCurrency.findFirst.mockResolvedValue(bnp);
    prisma.tipAccount.findMany.mockResolvedValue([
      { currencyCode: 'BNP', balanceAtomic: 0n, currency: bnp },
    ]);
    prisma.tipAccount.upsert.mockResolvedValue({ id: 'acc-1' });
    prisma.profile.findUnique.mockResolvedValue({ miningClaimedPoints: 0n });
    prisma.tipTransaction.groupBy.mockResolvedValue([]);
    prisma.tipTransaction.findMany.mockResolvedValue([]);
    prisma.tipTransaction.count.mockResolvedValue(0);

    service = new TipsService(
      prisma as any,
      { create: jest.fn() } as unknown as AuditLogService,
      { notifyMany: jest.fn() } as unknown as NotificationsService,
      bootstrap as unknown as TipBootstrapService,
    );
  });

  it('sums only tips in the sent and received overview totals', async () => {
    await service.getMyOverview(USER);

    const wheres = prisma.tipTransaction.groupBy.mock.calls.map(
      ([args]: [{ where: Record<string, unknown> }]) => args.where,
    );
    expect(wheres).toEqual([
      { senderUserId: USER, type: TipTransactionType.tip },
      { recipientUserId: USER, type: TipTransactionType.tip },
    ]);
  });

  it('lists only tips in tip history', async () => {
    await service.listTipHistory(USER, { direction: 'all' });

    const [findArgs] = prisma.tipTransaction.findMany.mock.calls[0];
    const [countArgs] = prisma.tipTransaction.count.mock.calls[0];
    expect(findArgs.where).toMatchObject({ type: TipTransactionType.tip });
    expect(countArgs.where).toMatchObject({ type: TipTransactionType.tip });
  });
});
