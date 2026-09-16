import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { NotificationType, TipTransactionType } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { NotificationsService } from '../notifications/notifications.service';
import { TipBootstrapService } from './tip-bootstrap';
import { TipTransfersService } from './tip-transfers.service';

const SENDER = '11111111-1111-4111-8111-111111111111';
const RECIPIENT = '22222222-2222-4222-8222-222222222222';

const bnp = {
  code: 'BNP',
  name: 'Blocnet Points',
  symbol: 'BNP',
  decimals: 3,
  kind: 'points',
  isEnabled: true,
  isActiveTippingCurrency: true,
};

function participant(id: string, username: string) {
  return {
    id,
    username,
    displayName: null,
    avatarUrl: null,
    currentLevel: null,
  };
}

function txRow(overrides: Record<string, unknown> = {}) {
  return {
    id: 'tx-1',
    type: TipTransactionType.transfer,
    senderAccountId: 'acc-sender',
    recipientAccountId: 'acc-recipient',
    feeAccountId: null,
    senderUserId: SENDER,
    recipientUserId: RECIPIENT,
    currencyCode: 'BNP',
    amountAtomic: 1500n,
    feeAtomic: 0n,
    totalDebitAtomic: 1500n,
    note: 'thanks',
    contextType: 'wallet_transfer',
    contextId: null,
    idempotencyKey: 'hashed',
    metadata: null,
    createdAt: new Date('2026-09-16T10:00:00Z'),
    currency: bnp,
    sender: participant(SENDER, 'alice'),
    recipient: participant(RECIPIENT, 'bob'),
    ...overrides,
  };
}

describe('TipTransfersService', () => {
  const prisma = {
    $transaction: jest.fn(),
    tipCurrency: { findUnique: jest.fn() },
    profile: { findUnique: jest.fn(), findFirst: jest.fn() },
    userBlock: { findUnique: jest.fn() },
    tipAccount: {
      upsert: jest.fn(),
      updateMany: jest.fn(),
      update: jest.fn(),
    },
    tipTransaction: { findUnique: jest.fn(), create: jest.fn() },
  };
  const auditLogService = { create: jest.fn() };
  const notificationsService = { notifyMany: jest.fn() };
  const bootstrap = { ensure: jest.fn() };

  let service: TipTransfersService;

  const dto = (overrides: Record<string, string> = {}) => ({
    recipient: '@Bob',
    amountAtomic: '1500',
    note: ' thanks ',
    idempotencyKey: 'client-key-123',
    ...overrides,
  });

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.$transaction.mockImplementation(
      async (callback: (tx: typeof prisma) => Promise<unknown>) =>
        callback(prisma),
    );
    prisma.tipCurrency.findUnique.mockResolvedValue(bnp);
    prisma.profile.findFirst.mockResolvedValue({
      id: RECIPIENT,
      isDeactivated: false,
    });
    // ensureUserTipAccount reads miningClaimedPoints for the BNP seed.
    prisma.profile.findUnique.mockResolvedValue({ miningClaimedPoints: 0n });
    prisma.userBlock.findUnique.mockResolvedValue(null);
    prisma.tipAccount.upsert.mockImplementation(
      ({ create }: { create: { ownerRef: string } }) =>
        Promise.resolve({
          id: create.ownerRef === SENDER ? 'acc-sender' : 'acc-recipient',
        }),
    );
    prisma.tipAccount.updateMany.mockResolvedValue({ count: 1 });
    prisma.tipAccount.update.mockResolvedValue({});
    prisma.tipTransaction.findUnique.mockResolvedValue(null);
    prisma.tipTransaction.create.mockResolvedValue(txRow());

    service = new TipTransfersService(
      prisma as any,
      auditLogService as unknown as AuditLogService,
      notificationsService as unknown as NotificationsService,
      bootstrap as unknown as TipBootstrapService,
    );
  });

  it('moves BNP between members with no fee, as a transfer row', async () => {
    const result = await service.sendTransfer(SENDER, dto());

    expect(prisma.profile.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { username: { equals: 'Bob', mode: 'insensitive' } },
      }),
    );
    expect(prisma.tipAccount.updateMany).toHaveBeenCalledWith({
      where: { id: 'acc-sender', balanceAtomic: { gte: 1500n } },
      data: { balanceAtomic: { decrement: 1500n } },
    });
    expect(prisma.tipAccount.update).toHaveBeenCalledWith({
      where: { id: 'acc-recipient' },
      data: { balanceAtomic: { increment: 1500n } },
    });
    // Only two balance writes: no fee vault credit.
    expect(prisma.tipAccount.update).toHaveBeenCalledTimes(1);

    const created = prisma.tipTransaction.create.mock.calls[0][0].data;
    expect(created).toMatchObject({
      type: TipTransactionType.transfer,
      feeAtomic: 0n,
      feeAccountId: null,
      totalDebitAtomic: 1500n,
      note: 'thanks',
      contextType: 'wallet_transfer',
    });
    // Namespaced, not the raw client key.
    expect(created.idempotencyKey).not.toBe('client-key-123');
    expect(created.idempotencyKey).toHaveLength(64);

    expect(auditLogService.create).toHaveBeenCalledWith(
      expect.objectContaining({
        action: FinancialAuditActions.TipTransferSent,
        resourceId: 'tx-1',
      }),
    );
    const [events] = notificationsService.notifyMany.mock.calls[0];
    expect(events[0]).toMatchObject({
      userId: RECIPIENT,
      type: NotificationType.wallet_transfer_received,
      body: '@alice sent you 1.5 BNP.',
    });

    expect(result).toMatchObject({
      id: 'tx-1',
      type: 'transfer',
      direction: 'sent',
      amountAtomic: '1500',
      amount: '1.5',
      fee: '0',
    });
  });

  it('resolves a profile id recipient by id', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      id: RECIPIENT,
      isDeactivated: false,
      miningClaimedPoints: 0n,
    });

    await service.sendTransfer(SENDER, dto({ recipient: RECIPIENT }));

    expect(prisma.profile.findFirst).not.toHaveBeenCalled();
    expect(prisma.tipTransaction.create).toHaveBeenCalled();
  });

  it('rejects when the balance does not cover the amount', async () => {
    prisma.tipAccount.updateMany.mockResolvedValue({ count: 0 });

    await expect(service.sendTransfer(SENDER, dto())).rejects.toThrow(
      new BadRequestException('Insufficient BNP balance'),
    );
    expect(prisma.tipAccount.update).not.toHaveBeenCalled();
    expect(prisma.tipTransaction.create).not.toHaveBeenCalled();
    expect(auditLogService.create).not.toHaveBeenCalled();
  });

  it('rejects sending to yourself', async () => {
    prisma.profile.findFirst.mockResolvedValue({
      id: SENDER,
      isDeactivated: false,
    });

    await expect(
      service.sendTransfer(SENDER, dto({ recipient: 'alice' })),
    ).rejects.toThrow(
      new BadRequestException('You cannot send BNP to yourself'),
    );
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('rejects when the recipient has blocked the sender', async () => {
    prisma.userBlock.findUnique.mockResolvedValue({ id: 'block-1' });

    await expect(service.sendTransfer(SENDER, dto())).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(prisma.userBlock.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          blockerId_blockedId: { blockerId: RECIPIENT, blockedId: SENDER },
        },
      }),
    );
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('rejects deactivated or unknown recipients', async () => {
    prisma.profile.findFirst.mockResolvedValue({
      id: RECIPIENT,
      isDeactivated: true,
    });
    await expect(service.sendTransfer(SENDER, dto())).rejects.toBeInstanceOf(
      NotFoundException,
    );

    prisma.profile.findFirst.mockResolvedValue(null);
    await expect(service.sendTransfer(SENDER, dto())).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('rejects a zero amount', async () => {
    await expect(
      service.sendTransfer(SENDER, dto({ amountAtomic: '0' })),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('is unavailable while the BNP currency is disabled', async () => {
    prisma.tipCurrency.findUnique.mockResolvedValue({
      ...bnp,
      isEnabled: false,
    });

    await expect(service.sendTransfer(SENDER, dto())).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it('replays an idempotent retry without moving BNP again', async () => {
    prisma.tipTransaction.findUnique.mockResolvedValue(txRow());

    const result = await service.sendTransfer(SENDER, dto());

    expect(result.id).toBe('tx-1');
    expect(prisma.tipAccount.updateMany).not.toHaveBeenCalled();
    expect(prisma.tipTransaction.create).not.toHaveBeenCalled();
    expect(auditLogService.create).not.toHaveBeenCalled();
    expect(notificationsService.notifyMany).not.toHaveBeenCalled();
  });

  it('refuses to reuse a key for a different transfer', async () => {
    prisma.tipTransaction.findUnique.mockResolvedValue(
      txRow({ amountAtomic: 999n }),
    );

    await expect(service.sendTransfer(SENDER, dto())).rejects.toBeInstanceOf(
      ConflictException,
    );
  });
});
