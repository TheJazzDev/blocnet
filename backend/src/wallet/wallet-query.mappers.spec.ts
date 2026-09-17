import {
  LedgerAccountType,
  LedgerReason,
  Prisma,
  WalletAsset,
  WithdrawalStatus,
} from '@prisma/client';
import {
  toTransactionResponse,
  toWithdrawalResponse,
} from './wallet-query.mappers';
import { WITHDRAWAL_FAILED_MESSAGE } from './withdrawal-failure';

const ME = '11111111-1111-4111-8111-111111111111';
const RAW =
  'Broadcast failed: HTTP request failed. URL: https://bsc-rpc.internal/abc Details: nonce too low';

function withdrawal(
  overrides: Partial<Parameters<typeof toWithdrawalResponse>[0]>,
) {
  return {
    id: 'w-1',
    asset: WalletAsset.BNT,
    toAddress: '0xabc',
    amount: new Prisma.Decimal('10'),
    feeAmount: new Prisma.Decimal('1'),
    netAmount: new Prisma.Decimal('9'),
    status: WithdrawalStatus.requested,
    reason: 'withdrawal',
    rejectReason: null,
    broadcastTxHash: null,
    requestedAt: new Date('2026-09-16T10:00:00Z'),
    reviewedAt: null,
    confirmedAt: null,
    failureReason: null,
    createdAt: new Date('2026-09-16T10:00:00Z'),
    updatedAt: new Date('2026-09-16T10:00:00Z'),
    ...overrides,
  };
}

function releaseEntry(idempotencyKey: string, metadata: Prisma.JsonObject) {
  const account = (accountType: LedgerAccountType) => ({
    userId: ME,
    accountType,
    currency: WalletAsset.BNT,
    user: null,
    wallet: null,
  });
  return {
    id: 'le-1',
    debitAccountId: 'hold',
    creditAccountId: 'user',
    amount: new Prisma.Decimal('10'),
    feeAmount: new Prisma.Decimal('0'),
    reason: LedgerReason.withdrawal_reject_release,
    referenceId: null,
    idempotencyKey,
    metadata,
    createdAt: new Date('2026-09-16T10:00:00Z'),
    debitAccount: account(LedgerAccountType.hold),
    creditAccount: account(LedgerAccountType.user),
  };
}

describe('toWithdrawalResponse (member view of failures)', () => {
  it('never returns a raw failure reason stored on an old reverted row', () => {
    const response = toWithdrawalResponse(
      withdrawal({
        status: WithdrawalStatus.reverted,
        failureReason: RAW,
        rejectReason: RAW,
      }),
    );

    expect(response.failureReason).toBe(WITHDRAWAL_FAILED_MESSAGE);
    expect(response.rejectReason).toBeNull();
    expect(JSON.stringify(response)).not.toContain('Broadcast failed');
  });

  it('shows the safe message for a reverted row even with no stored reason', () => {
    const response = toWithdrawalResponse(
      withdrawal({ status: WithdrawalStatus.reverted }),
    );
    expect(response.failureReason).toBe(WITHDRAWAL_FAILED_MESSAGE);
  });

  it('keeps an admin rejection reason, which is written for the member', () => {
    const response = toWithdrawalResponse(
      withdrawal({
        status: WithdrawalStatus.rejected,
        rejectReason: 'Address is on a sanctions list',
      }),
    );
    expect(response.rejectReason).toBe('Address is on a sanctions list');
    expect(response.failureReason).toBeNull();
  });

  it('leaves a healthy withdrawal without failure text', () => {
    const response = toWithdrawalResponse(
      withdrawal({ status: WithdrawalStatus.confirmed }),
    );
    expect(response.failureReason).toBeNull();
    expect(response.rejectReason).toBeNull();
  });
});

describe('toTransactionResponse (member view of ledger metadata)', () => {
  it('replaces the raw reason on a legacy settlement revert entry', () => {
    const response = toTransactionResponse(
      ME,
      releaseEntry('withdrawal:abc:revert', {
        withdrawalId: 'w-1',
        asset: 'BNT',
        reason: 'Missing treasury wallet ID for mainnet',
      }),
    );

    expect(response.metadata).toEqual({
      withdrawalId: 'w-1',
      asset: 'BNT',
      reason: WITHDRAWAL_FAILED_MESSAGE,
    });
  });

  it('drops the internal detail from a new settlement revert entry', () => {
    const response = toTransactionResponse(
      ME,
      releaseEntry('withdrawal:abc:revert', {
        withdrawalId: 'w-1',
        asset: 'BNT',
        kind: 'settlement_revert',
        reason: WITHDRAWAL_FAILED_MESSAGE,
        internalDetail: RAW,
      }),
    );

    expect(response.metadata).not.toHaveProperty('internalDetail');
    expect(JSON.stringify(response)).not.toContain('nonce too low');
    expect(response.metadata?.reason).toBe(WITHDRAWAL_FAILED_MESSAGE);
  });

  it('treats a truncated key as a revert when the entry records the asset', () => {
    const response = toTransactionResponse(
      ME,
      releaseEntry('x'.repeat(128), {
        withdrawalId: 'w-1',
        asset: 'BNT',
        reason: `On-chain withdrawal failed: 0x${'a'.repeat(64)}`,
      }),
    );
    expect(response.metadata?.reason).toBe(WITHDRAWAL_FAILED_MESSAGE);
  });

  it('keeps the reason an admin wrote when rejecting', () => {
    const response = toTransactionResponse(
      ME,
      releaseEntry('withdrawal:abc:reject', {
        withdrawalId: 'w-1',
        reason: 'Please verify your identity first',
      }),
    );
    expect(response.metadata?.reason).toBe('Please verify your identity first');
  });
});
