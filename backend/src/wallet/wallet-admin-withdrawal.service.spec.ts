import { Prisma, WithdrawalStatus } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { WalletAdminWithdrawalService } from './wallet-admin-withdrawal.service';
import { WITHDRAWAL_FAILED_MESSAGE } from './withdrawal-failure';

function row(overrides: Record<string, unknown>) {
  return {
    id: 'w-1',
    status: WithdrawalStatus.reverted,
    toAddress: '0xabc',
    amount: new Prisma.Decimal('10'),
    feeAmount: new Prisma.Decimal('1'),
    netAmount: new Prisma.Decimal('9'),
    reason: 'withdrawal',
    rejectReason: null,
    failureReason: WITHDRAWAL_FAILED_MESSAGE,
    broadcastTxHash: null,
    confirmations: 0,
    requester: { id: 'user-1', email: 'u@test.dev', displayName: 'U' },
    reviewer: null,
    requestedAt: new Date(),
    reviewedAt: null,
    confirmedAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    finalizeLedgerEntry: null,
    ...overrides,
  };
}

describe('WalletAdminWithdrawalService.listWithdrawals (failure detail)', () => {
  const prisma = {
    withdrawalRequest: { findMany: jest.fn(), count: jest.fn() },
  };
  const service = new WalletAdminWithdrawalService(
    prisma as unknown as PrismaService,
    {} as AuditLogService,
  );

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.withdrawalRequest.count.mockResolvedValue(1);
  });

  it('shows operators the internal detail kept on the revert entry', async () => {
    prisma.withdrawalRequest.findMany.mockResolvedValue([
      row({
        finalizeLedgerEntry: {
          metadata: {
            reason: WITHDRAWAL_FAILED_MESSAGE,
            internalDetail: 'Broadcast failed: nonce too low',
          },
        },
      }),
    ]);

    const result = await service.listWithdrawals({});

    expect(result.data[0].failureReason).toBe(
      'Broadcast failed: nonce too low',
    );
    expect(result.data[0].failureMessage).toBe(WITHDRAWAL_FAILED_MESSAGE);
    expect(
      prisma.withdrawalRequest.findMany.mock.calls[0][0].include
        .finalizeLedgerEntry,
    ).toEqual({ select: { metadata: true } });
  });

  it('keeps showing the stored text on rows written before the split', async () => {
    prisma.withdrawalRequest.findMany.mockResolvedValue([
      row({
        failureReason: 'Missing treasury wallet ID for mainnet',
        rejectReason: 'Missing treasury wallet ID for mainnet',
        finalizeLedgerEntry: {
          metadata: { reason: 'Missing treasury wallet ID for mainnet' },
        },
      }),
    ]);

    const result = await service.listWithdrawals({});

    expect(result.data[0].failureReason).toBe(
      'Missing treasury wallet ID for mainnet',
    );
    expect(result.data[0].rejectReason).toBe(
      'Missing treasury wallet ID for mainnet',
    );
  });
});
