import { Logger } from '@nestjs/common';
import {
  ChainEnvironment,
  LedgerReason,
  Prisma,
  WalletAsset,
  WalletStatus,
  WithdrawalStatus,
} from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { CustodyAdapter } from './custody/custody.adapter';
import { WalletConfigService } from './wallet-config.service';
import { WalletWithdrawalSettlementService } from './wallet-withdrawal-settlement.service';
import { WITHDRAWAL_FAILED_MESSAGE } from './withdrawal-failure';

const RAW_RPC =
  'HTTP request failed. URL: https://bsc-mainnet.internal/key-123 Details: nonce too low';

function makeWithdrawal(overrides: Record<string, unknown> = {}) {
  return {
    id: 'w-1',
    userId: 'user-1',
    walletId: 'wallet-1',
    toAddress: `0x${'1'.repeat(40)}`,
    amount: new Prisma.Decimal('10'),
    feeAmount: new Prisma.Decimal('1'),
    netAmount: new Prisma.Decimal('9'),
    status: WithdrawalStatus.broadcasting,
    asset: WalletAsset.BNT,
    idempotencyKey: 'withdrawal:w-1',
    reviewedBy: 'admin-1',
    confirmations: 0,
    confirmedAt: null,
    finalizeLedgerEntryId: null,
    broadcastTxHash: null,
    wallet: {
      chainEnvironment: ChainEnvironment.mainnet,
      status: WalletStatus.ready,
    },
    ...overrides,
  };
}

function setup(options: {
  network?: boolean;
  treasuryWalletId?: string | null;
  transferError?: Error;
}) {
  const withdrawal = makeWithdrawal();
  const account = (id: string) => ({
    id,
    available: new Prisma.Decimal('100'),
    locked: new Prisma.Decimal('100'),
  });

  const tx = {
    withdrawalRequest: {
      findUnique: jest.fn().mockResolvedValue(withdrawal),
      update: jest
        .fn()
        .mockResolvedValue({ ...withdrawal, status: 'reverted' }),
    },
    ledgerAccount: {
      findUnique: jest
        .fn()
        .mockImplementation(({ where }) =>
          Promise.resolve(
            account(where.userId_accountType_currency.accountType),
          ),
        ),
      update: jest.fn().mockResolvedValue({}),
    },
    ledgerEntry: {
      findUnique: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockResolvedValue({ id: 'le-revert' }),
    },
  };

  const prisma = {
    withdrawalRequest: {
      updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      findMany: jest.fn().mockResolvedValue([{ id: withdrawal.id }]),
      findUnique: jest.fn().mockResolvedValue(withdrawal),
      update: jest.fn(),
    },
    $transaction: jest.fn((fn: (client: typeof tx) => unknown) => fn(tx)),
  };

  const walletConfigService = {
    getDepositNetworkConfig: jest.fn().mockReturnValue(
      options.network === false
        ? null
        : {
            asset: WalletAsset.BNT,
            assetKind: 'token',
            chainEnvironment: ChainEnvironment.mainnet,
            chainId: 56,
            tokenAddress: `0x${'2'.repeat(40)}`,
            decimals: 18,
          },
    ),
    getTreasuryWalletIdForEnvironment: jest
      .fn()
      .mockReturnValue(
        options.treasuryWalletId === undefined
          ? 'treasury-1'
          : options.treasuryWalletId,
      ),
    getWithdrawalConfirmationsForEnvironment: jest.fn().mockReturnValue(3),
  };

  const auditLogService = { create: jest.fn().mockResolvedValue(undefined) };
  const custodyAdapter = {
    createWallet: jest.fn(),
    transferNative: jest.fn(),
    transferToken: options.transferError
      ? jest.fn().mockRejectedValue(options.transferError)
      : jest.fn().mockResolvedValue({ txHash: '0xabc', simulated: false }),
  };

  const service = new WalletWithdrawalSettlementService(
    prisma as unknown as PrismaService,
    walletConfigService as unknown as WalletConfigService,
    auditLogService as unknown as AuditLogService,
    custodyAdapter as unknown as CustodyAdapter,
  );

  return { service, tx, auditLogService };
}

describe('WalletWithdrawalSettlementService revert (F-37)', () => {
  let warn: jest.SpyInstance;

  beforeEach(() => {
    warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    warn.mockRestore();
  });

  it.each([
    [
      'a raw broadcast error',
      { transferError: new Error(RAW_RPC) },
      `Broadcast failed: ${RAW_RPC}`,
    ],
    [
      'a missing treasury wallet',
      { treasuryWalletId: null },
      'Missing treasury wallet ID for mainnet',
    ],
    [
      'a missing network config',
      { network: false },
      'Missing network config for mainnet',
    ],
  ])(
    'stores only the safe message for %s and keeps the detail for operators',
    async (_label, options, detail) => {
      const { service, tx, auditLogService } = setup(options);

      await service.processApprovedWithdrawals();

      const rowUpdate = tx.withdrawalRequest.update.mock.calls[0][0].data;
      expect(rowUpdate.status).toBe(WithdrawalStatus.reverted);
      expect(rowUpdate.failureReason).toBe(WITHDRAWAL_FAILED_MESSAGE);
      expect(rowUpdate.rejectReason).toBeUndefined();
      expect(JSON.stringify(rowUpdate)).not.toContain(detail);

      const entry = tx.ledgerEntry.create.mock.calls[0][0].data;
      expect(entry.reason).toBe(LedgerReason.withdrawal_reject_release);
      expect(entry.metadata.reason).toBe(WITHDRAWAL_FAILED_MESSAGE);
      expect(entry.metadata.internalDetail).toBe(detail);

      expect(auditLogService.create).toHaveBeenCalledWith(
        expect.objectContaining({
          resourceId: 'w-1',
          metadata: expect.objectContaining({ reason: detail }),
        }),
      );
      expect(warn).toHaveBeenCalledWith(expect.stringContaining(detail));
    },
  );
});
