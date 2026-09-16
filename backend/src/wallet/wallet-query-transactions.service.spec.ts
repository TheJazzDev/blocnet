import { Prisma, TipTransactionType, WalletAsset } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { WalletAssetPricingService } from './wallet-asset-pricing.service';
import { WalletConfigService } from './wallet-config.service';
import { WalletPointsService } from './wallet-points.service';
import { WalletProvisioningService } from './wallet-provisioning.service';
import { WalletQueryService } from './wallet-query.service';

const ME = '11111111-1111-4111-8111-111111111111';
const BOB = '22222222-2222-4222-8222-222222222222';

function party(id: string, username: string) {
  return { id, username, displayName: null };
}

function pointsRow(overrides: Record<string, unknown>) {
  return {
    id: 'tt-1',
    type: TipTransactionType.transfer,
    senderUserId: ME,
    recipientUserId: BOB,
    currencyCode: 'BNP',
    amountAtomic: 2500n,
    feeAtomic: 0n,
    totalDebitAtomic: 2500n,
    note: 'lunch',
    contextType: 'wallet_transfer',
    contextId: null,
    sender: party(ME, 'me'),
    recipient: party(BOB, 'bob'),
    createdAt: new Date('2026-09-16T10:00:00Z'),
    ...overrides,
  };
}

function ledgerEntry(id: string, createdAt: string) {
  const account = (userId: string | null) => ({
    userId,
    accountType: 'user',
    currency: WalletAsset.BNT,
    user: null,
    wallet: null,
  });
  return {
    id,
    reason: 'deposit_credit',
    amount: new Prisma.Decimal('1'),
    feeAmount: new Prisma.Decimal('0'),
    referenceId: null,
    metadata: null,
    createdAt: new Date(createdAt),
    debitAccount: account(null),
    creditAccount: account(ME),
  };
}

describe('WalletQueryService.listWalletTransactions (BNP)', () => {
  const prisma = {
    ledgerEntry: { findMany: jest.fn() },
    tipTransaction: { findMany: jest.fn() },
  };
  const walletProvisioningService = {
    ensureWalletForUser: jest.fn().mockResolvedValue({ status: 'disabled' }),
  };
  const walletConfigService = { isAssetEnabled: () => true };
  let service: WalletQueryService;

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.ledgerEntry.findMany.mockResolvedValue([]);
    prisma.tipTransaction.findMany.mockResolvedValue([]);
    service = new WalletQueryService(
      prisma as unknown as PrismaService,
      walletConfigService as unknown as WalletConfigService,
      walletProvisioningService as unknown as WalletProvisioningService,
      {} as WalletAssetPricingService,
      new WalletPointsService(prisma as unknown as PrismaService),
    );
  });

  it('labels BNP transfers and tips in the wallet row shape', async () => {
    prisma.tipTransaction.findMany.mockResolvedValue([
      pointsRow({}),
      pointsRow({
        id: 'tt-2',
        type: TipTransactionType.tip,
        senderUserId: BOB,
        recipientUserId: ME,
        sender: party(BOB, 'bob'),
        recipient: party(ME, 'me'),
        feeAtomic: 125n,
      }),
    ]);

    const rows = await service.listWalletTransactions(ME, {
      asset: 'BNP',
      limit: 10,
    });

    expect(prisma.ledgerEntry.findMany).not.toHaveBeenCalled();
    expect(prisma.tipTransaction.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          currencyCode: 'BNP',
          OR: [{ senderUserId: ME }, { recipientUserId: ME }],
        },
        skip: 0,
        take: 10,
      }),
    );
    expect(rows[0]).toEqual({
      id: 'tt-1',
      asset: 'BNP',
      direction: 'outgoing',
      reason: 'bnp_transfer',
      amount: '2.5',
      feeAmount: '0',
      debit: { userId: ME, accountType: 'user' },
      credit: { userId: BOB, accountType: 'user' },
      referenceId: 'tt-1',
      metadata: {
        source: 'bnp_ledger',
        ledgerType: 'transfer',
        label: 'BNP transfer',
        note: 'lunch',
        contextType: 'wallet_transfer',
        contextId: null,
      },
      counterparty: {
        userId: BOB,
        username: 'bob',
        displayName: null,
        walletAddress: null,
      },
      createdAt: new Date('2026-09-16T10:00:00Z'),
    });
    // A tip received: incoming, and the sender's fee is not the recipient's.
    expect(rows[1]).toMatchObject({
      direction: 'incoming',
      reason: 'bnp_tip',
      feeAmount: '0',
      metadata: { label: 'Tip' },
      counterparty: { username: 'bob' },
    });
  });

  describe('minted BNP (F-63)', () => {
    // Reward and reversal rows name the member on both sides.
    const selfRow = (overrides: Record<string, unknown>) =>
      pointsRow({
        type: TipTransactionType.reward,
        senderUserId: ME,
        recipientUserId: ME,
        sender: party(ME, 'me'),
        recipient: party(ME, 'me'),
        amountAtomic: 120_000n,
        feeAtomic: 0n,
        totalDebitAtomic: 0n,
        note: null,
        ...overrides,
      });

    it('shows mining and quest rewards as received, with the credited amount', async () => {
      prisma.tipTransaction.findMany.mockResolvedValue([
        selfRow({
          id: 'tt-mine',
          contextType: 'mining_claim',
          contextId: 'session-1',
        }),
        selfRow({
          id: 'tt-quest',
          amountAtomic: 35_000n,
          contextType: 'quest_reward',
          contextId: 'submission-1',
        }),
      ]);

      const rows = await service.listWalletTransactions(ME, {
        asset: 'BNP',
        limit: 10,
      });

      expect(rows[0]).toEqual({
        id: 'tt-mine',
        asset: 'BNP',
        direction: 'incoming',
        reason: 'bnp_reward',
        amount: '120',
        feeAmount: '0',
        debit: { userId: null, accountType: 'system' },
        credit: { userId: ME, accountType: 'user' },
        referenceId: 'tt-mine',
        metadata: {
          source: 'bnp_ledger',
          ledgerType: 'reward',
          label: 'Mining reward',
          note: null,
          contextType: 'mining_claim',
          contextId: 'session-1',
        },
        counterparty: null,
        createdAt: new Date('2026-09-16T10:00:00Z'),
      });
      expect(rows[1]).toMatchObject({
        direction: 'incoming',
        reason: 'bnp_reward',
        amount: '35',
        feeAmount: '0',
        metadata: { label: 'Quest reward' },
        counterparty: null,
      });
    });

    it('never reads a reward amount from totalDebitAtomic', async () => {
      prisma.tipTransaction.findMany.mockResolvedValue([
        selfRow({ contextType: 'mining_claim', totalDebitAtomic: 999n }),
      ]);

      const [row] = await service.listWalletTransactions(ME, {
        asset: 'BNP',
      });

      expect(row).toMatchObject({ direction: 'incoming', amount: '120' });
    });

    it('shows a revoked quest reward as a debit', async () => {
      prisma.tipTransaction.findMany.mockResolvedValue([
        selfRow({
          type: TipTransactionType.adjustment,
          amountAtomic: 20_000n,
          contextType: 'quest_reward_revoked',
          contextId: 'submission-1',
        }),
      ]);

      const [row] = await service.listWalletTransactions(ME, {
        asset: 'BNP',
      });

      expect(row).toMatchObject({
        direction: 'outgoing',
        reason: 'bnp_adjustment',
        amount: '20',
        feeAmount: '0',
        debit: { userId: ME, accountType: 'user' },
        credit: { userId: null, accountType: 'system' },
        metadata: { label: 'Quest reward reversed' },
        counterparty: null,
      });
    });
  });

  it('merges on-chain and BNP rows newest-first when no asset is given', async () => {
    prisma.ledgerEntry.findMany.mockResolvedValue([
      ledgerEntry('le-new', '2026-09-16T12:00:00Z'),
      ledgerEntry('le-old', '2026-09-14T12:00:00Z'),
    ]);
    prisma.tipTransaction.findMany.mockResolvedValue([
      pointsRow({ id: 'tt-mid', createdAt: new Date('2026-09-15T12:00:00Z') }),
    ]);

    const rows = await service.listWalletTransactions(ME, {
      limit: 2,
      offset: 1,
    });

    // Both sources are read up to the end of the page, in parallel.
    expect(prisma.ledgerEntry.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ skip: 0, take: 3 }),
    );
    expect(prisma.tipTransaction.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ skip: 0, take: 3 }),
    );
    expect(rows.map((row) => row.id)).toEqual(['tt-mid', 'le-old']);
  });

  it('keeps an on-chain asset filter on the custody ledger only', async () => {
    await service.listWalletTransactions(ME, { asset: WalletAsset.BNT });

    expect(prisma.ledgerEntry.findMany).toHaveBeenCalled();
    expect(prisma.tipTransaction.findMany).not.toHaveBeenCalled();
  });
});
