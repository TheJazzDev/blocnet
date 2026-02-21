import { BadRequestException } from '@nestjs/common';
import { LedgerAccountType, LedgerReason, Prisma } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { WalletConfigService } from './wallet-config.service';
import { WalletProvisioningService } from './wallet-provisioning.service';
import { WalletService } from './wallet.service';

describe('WalletService', () => {
  const prisma = {
    ledgerEntry: {
      aggregate: jest.fn(),
    },
    kycProfile: {
      findUnique: jest.fn(),
    },
    riskLimit: {
      findUnique: jest.fn(),
    },
    $transaction: jest.fn(),
  };

  const walletConfigService = {
    walletEnabled: true,
  } as unknown as WalletConfigService;

  const walletProvisioningService = {
    ensureWalletForUser: jest.fn(),
    ensureUserLedgerAccount: jest.fn(),
  } as unknown as WalletProvisioningService;

  const auditLogService = {
    create: jest.fn(),
  } as unknown as AuditLogService;

  let service: WalletService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new WalletService(
      prisma as unknown as PrismaService,
      walletConfigService,
      walletProvisioningService,
      auditLogService,
    );
  });

  it('rejects internal transfer when daily tier limit is exceeded', async () => {
    (
      walletProvisioningService.ensureWalletForUser as jest.Mock
    ).mockResolvedValue({
      id: 'wallet-1',
      userId: 'user-1',
    });
    (
      walletProvisioningService.ensureUserLedgerAccount as jest.Mock
    ).mockResolvedValue({
      id: 'ledger-user-1',
    });
    prisma.kycProfile.findUnique.mockResolvedValue({ tier: 'basic' });
    prisma.riskLimit.findUnique.mockResolvedValue({
      tier: 'basic',
      maxInternalTransferPerDay: '5',
      maxWithdrawalPerTx: '0',
      maxWithdrawalPerDay: '0',
      requiresKyc: false,
    });
    prisma.ledgerEntry.aggregate.mockResolvedValue({
      _sum: {
        amount: new Prisma.Decimal('4'),
      },
    });

    await expect(
      service.createInternalTransfer('user-1', {
        amount: '2',
        toUserId: 'user-2',
      }),
    ).rejects.toThrow(BadRequestException);

    expect(prisma.ledgerEntry.aggregate).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          reason: LedgerReason.internal_transfer,
          debitAccount: { userId: 'user-1' },
        }),
      }),
    );
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('allows internal transfer within limit and returns existing idempotent entry', async () => {
    const createdAt = new Date('2026-02-20T12:00:00.000Z');
    (walletProvisioningService.ensureWalletForUser as jest.Mock)
      .mockResolvedValueOnce({
        id: 'wallet-1',
        userId: 'user-1',
      })
      .mockResolvedValueOnce({
        id: 'wallet-2',
        userId: 'user-2',
      });
    (walletProvisioningService.ensureUserLedgerAccount as jest.Mock)
      .mockResolvedValueOnce({ id: 'ledger-user-1' })
      .mockResolvedValueOnce({ id: 'ledger-user-2' });

    prisma.kycProfile.findUnique.mockResolvedValue({ tier: 'basic' });
    prisma.riskLimit.findUnique.mockResolvedValue({
      tier: 'basic',
      maxInternalTransferPerDay: '10',
      maxWithdrawalPerTx: '0',
      maxWithdrawalPerDay: '0',
      requiresKyc: false,
    });
    prisma.ledgerEntry.aggregate.mockResolvedValue({
      _sum: {
        amount: new Prisma.Decimal('3'),
      },
    });

    const existingEntry = {
      id: 'entry-1',
      debitAccountId: 'ledger-user-1',
      creditAccountId: 'ledger-user-2',
      amount: new Prisma.Decimal('2'),
      feeAmount: new Prisma.Decimal('0'),
      reason: LedgerReason.internal_transfer,
      idempotencyKey: 'itr-fixed-idempotency',
      referenceId: null,
      metadata: null,
      createdAt,
      debitAccount: {
        userId: 'user-1',
        accountType: LedgerAccountType.user,
      },
      creditAccount: {
        userId: 'user-2',
        accountType: LedgerAccountType.user,
      },
    };

    prisma.$transaction.mockImplementation(
      async (
        callback: (tx: {
          ledgerEntry: { findUnique: jest.Mock };
        }) => Promise<unknown>,
      ) =>
        callback({
          ledgerEntry: {
            findUnique: jest.fn().mockResolvedValue(existingEntry),
          },
        }),
    );

    const result = await service.createInternalTransfer('user-1', {
      amount: '2',
      toUserId: 'user-2',
      idempotencyKey: 'itr-fixed-idempotency',
    });

    expect(result).toEqual(
      expect.objectContaining({
        id: 'entry-1',
        direction: 'outgoing',
        amount: '2',
        feeAmount: '0',
        reason: LedgerReason.internal_transfer,
        createdAt,
      }),
    );
    expect(auditLogService.create).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: 'user-1',
        action: 'ledger.transfer.internal',
      }),
    );
  });
});
