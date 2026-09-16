import { createFakeMiningDb, type FakeSessionRow } from './mining-prisma.fake';
import {
  applyClaimSettlement,
  applyExpirySettlement,
  computeClaimDeadline,
  creditBnpTipAccount,
  debitBnpTipAccount,
  isClaimWindowExpired,
  isClaimable,
  MiningSessionAlreadySettledError,
  resolveClaimPoints,
} from './mining-settlement';
import {
  miningClaimRewardContext,
  questRewardRevokedContext,
} from './bnp-tip-account';

const HOUR = 60 * 60 * 1000;
const CONFIG = { claimWindowHours: 48 };

function session(overrides: Partial<FakeSessionRow> = {}): FakeSessionRow {
  const startsAt = new Date('2026-03-01T00:00:00.000Z');
  return {
    id: 'session-1',
    userId: 'user-1',
    startsAt,
    endsAt: new Date(startsAt.getTime() + 24 * HOUR),
    claimedAt: null,
    expiredAt: null,
    basePointsPerCycle: 120,
    effectivePointsPerCycle: 120,
    boostBpsSnapshot: 0,
    activeReferralsSnapshot: 0,
    ...overrides,
  };
}

describe('mining settlement', () => {
  describe('claim window maths', () => {
    const ended = session();

    it('keeps a cycle claimable inside the window', () => {
      const asOf = new Date(ended.endsAt.getTime() + 47 * HOUR);
      expect(isClaimable(ended, asOf, CONFIG)).toBe(true);
      expect(isClaimWindowExpired(ended, asOf, CONFIG)).toBe(false);
    });

    it('expires a cycle past the window', () => {
      const asOf = new Date(ended.endsAt.getTime() + 49 * HOUR);
      expect(isClaimable(ended, asOf, CONFIG)).toBe(false);
      expect(isClaimWindowExpired(ended, asOf, CONFIG)).toBe(true);
      expect(computeClaimDeadline(ended.endsAt, CONFIG)).toEqual(
        new Date(ended.endsAt.getTime() + 48 * HOUR),
      );
    });

    it('is not claimable before the cycle ends', () => {
      const asOf = new Date(ended.endsAt.getTime() - HOUR);
      expect(isClaimable(ended, asOf, CONFIG)).toBe(false);
    });
  });

  describe('resolveClaimPoints', () => {
    it('prefers the accrued checkpoint sum', () => {
      expect(resolveClaimPoints(168, session())).toBe(168);
    });

    it('falls back to the snapshotted cycle value when nothing accrued', () => {
      expect(resolveClaimPoints(0, session())).toBe(120);
      expect(resolveClaimPoints(null, session())).toBe(120);
    });
  });

  describe('applyClaimSettlement', () => {
    it('pays out once and refuses a second settlement of the same cycle', async () => {
      const db = createFakeMiningDb({ sessions: [session()] });
      const claimedAt = new Date('2026-03-03T00:00:00.000Z');
      const input = {
        userId: 'user-1',
        session: db.sessions[0],
        claimedAt,
        claimPoints: 120,
        checkpointCount: 24,
      };

      await applyClaimSettlement(db.client as never, input);

      await expect(
        applyClaimSettlement(db.client as never, input),
      ).rejects.toBeInstanceOf(MiningSessionAlreadySettledError);

      expect(db.ledger).toHaveLength(1);
      expect(db.profile.miningClaimedPoints).toBe(120n);
    });

    it('writes exactly one reward row for the claim (F-63)', async () => {
      const db = createFakeMiningDb({ sessions: [session()] });
      const input = {
        userId: 'user-1',
        session: db.sessions[0],
        claimedAt: new Date('2026-03-03T00:00:00.000Z'),
        claimPoints: 120,
        checkpointCount: 24,
      };

      await applyClaimSettlement(db.client as never, input);
      await expect(
        applyClaimSettlement(db.client as never, input),
      ).rejects.toBeInstanceOf(MiningSessionAlreadySettledError);

      expect(db.tipTransactions).toEqual([
        expect.objectContaining({
          type: 'reward',
          senderUserId: 'user-1',
          recipientUserId: 'user-1',
          senderAccountId: 'tip-account-user-1',
          recipientAccountId: 'tip-account-user-1',
          currencyCode: 'BNP',
          amountAtomic: 120_000n,
          feeAtomic: 0n,
          totalDebitAtomic: 0n,
          contextType: 'mining_claim',
          contextId: 'session-1',
          idempotencyKey: 'mining-claim:session-1',
        }),
      ]);
    });
  });

  describe('F-39 backfill semantics', () => {
    it('grants a forfeited cycle exactly once (idempotent re-run)', async () => {
      const db = createFakeMiningDb({
        sessions: [session({ expiredAt: new Date('2026-03-05T00:00:00.000Z') })],
      });
      const input = {
        userId: 'user-1',
        session: db.sessions[0],
        claimedAt: new Date('2026-03-06T00:00:00.000Z'),
        claimPoints: 120,
        checkpointCount: 24,
        reclaimForfeited: true,
        extraLedgerMetadata: { backfill: 'F-39' },
      };

      await applyClaimSettlement(db.client as never, input);

      expect(db.profile.miningClaimedPoints).toBe(120n);
      expect(db.sessions[0].claimedAt).not.toBeNull();
      // Paid or forfeited, never both.
      expect(db.sessions[0].expiredAt).toBeNull();
      expect(db.ledger).toEqual([
        expect.objectContaining({
          source: 'cycle_claim',
          points: 120,
          metadata: expect.objectContaining({ backfill: 'F-39' }),
        }),
      ]);

      // Second run of the backfill.
      await expect(
        applyClaimSettlement(db.client as never, input),
      ).rejects.toBeInstanceOf(MiningSessionAlreadySettledError);

      expect(db.ledger).toHaveLength(1);
      expect(db.profile.miningClaimedPoints).toBe(120n);
    });

    it('the live claim path never resurrects a forfeited cycle', async () => {
      const db = createFakeMiningDb({
        sessions: [session({ expiredAt: new Date('2026-03-05T00:00:00.000Z') })],
      });

      await expect(
        applyClaimSettlement(db.client as never, {
          userId: 'user-1',
          session: db.sessions[0],
          claimedAt: new Date('2026-03-06T00:00:00.000Z'),
          claimPoints: 120,
          checkpointCount: 24,
        }),
      ).rejects.toBeInstanceOf(MiningSessionAlreadySettledError);

      expect(db.ledger).toHaveLength(0);
      expect(db.profile.miningClaimedPoints).toBe(0n);
    });
  });

  describe('applyExpirySettlement', () => {
    it('forfeits once and reports no-op on a repeat', async () => {
      const db = createFakeMiningDb({ sessions: [session()] });
      const expiredAt = new Date('2026-03-05T00:00:00.000Z');

      await expect(
        applyExpirySettlement(db.client as never, {
          sessionId: 'session-1',
          expiredAt,
        }),
      ).resolves.toBe(true);

      await expect(
        applyExpirySettlement(db.client as never, {
          sessionId: 'session-1',
          expiredAt,
        }),
      ).resolves.toBe(false);

      expect(db.sessions[0].expiredAt).toEqual(expiredAt);
      expect(db.sessions[0].claimedAt).toBeNull();
      expect(db.profile.miningClaimedPoints).toBe(0n);
    });
  });

  describe('BNP tip account helpers (F-52, F-63)', () => {
    const key = {
      accountType: 'user',
      ownerRef: 'user-1',
      currencyCode: 'BNP',
    };
    const claimCtx = miningClaimRewardContext('session-9');
    const revokeCtx = questRewardRevokedContext('submission-9');

    function tipTx() {
      const rows: Array<Record<string, any>> = [];
      return {
        rows,
        tipCurrency: { upsert: jest.fn().mockResolvedValue({}) },
        tipAccount: {
          upsert: jest.fn().mockResolvedValue({ id: 'acct-1' }),
          findUnique: jest.fn(),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        tipTransaction: {
          findUnique: jest.fn(async ({ where }: any) =>
            rows.find((row) => row.idempotencyKey === where.idempotencyKey) ??
            null,
          ),
          create: jest.fn(async ({ data }: any) => {
            rows.push(data);
            return data;
          }),
        },
      };
    }

    it('credits points x 1000 atomic units and records a reward row', async () => {
      const tx = tipTx();

      await expect(
        creditBnpTipAccount(tx as never, 'user-1', 7, claimCtx),
      ).resolves.toBe(7000n);

      expect(tx.tipAccount.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          update: { userId: 'user-1', balanceAtomic: { increment: 7000n } },
        }),
      );
      expect(tx.rows).toEqual([
        expect.objectContaining({
          type: 'reward',
          senderAccountId: 'acct-1',
          recipientAccountId: 'acct-1',
          amountAtomic: 7000n,
          totalDebitAtomic: 0n,
          idempotencyKey: 'mining-claim:session-9',
        }),
      ]);
    });

    it('is idempotent: a repeated credit moves nothing and writes nothing', async () => {
      const tx = tipTx();

      await creditBnpTipAccount(tx as never, 'user-1', 7, claimCtx);
      await expect(
        creditBnpTipAccount(tx as never, 'user-1', 7, claimCtx),
      ).resolves.toBe(0n);

      expect(tx.tipAccount.upsert).toHaveBeenCalledTimes(1);
      expect(tx.rows).toHaveLength(1);
    });

    it('credits nothing and writes no row for zero points', async () => {
      const tx = tipTx();

      await creditBnpTipAccount(tx as never, 'user-1', 0, claimCtx);

      expect(tx.tipAccount.upsert).not.toHaveBeenCalled();
      expect(tx.tipTransaction.create).not.toHaveBeenCalled();
    });

    it('debits the full amount when the balance covers it, as an adjustment row', async () => {
      const tx = tipTx();
      tx.tipAccount.findUnique.mockResolvedValue({
        id: 'acct-1',
        balanceAtomic: 90_000n,
      });

      await expect(
        debitBnpTipAccount(tx as never, 'user-1', 35, revokeCtx),
      ).resolves.toBe(35_000n);
      expect(tx.tipAccount.updateMany).toHaveBeenCalledWith({
        where: { ...key, balanceAtomic: { gte: 35_000n } },
        data: { balanceAtomic: { decrement: 35_000n } },
      });
      expect(tx.rows).toEqual([
        expect.objectContaining({
          type: 'adjustment',
          senderUserId: 'user-1',
          recipientUserId: 'user-1',
          amountAtomic: 35_000n,
          contextType: 'quest_reward_revoked',
          contextId: 'submission-9',
          idempotencyKey: 'quest-reward-revoked:submission-9',
        }),
      ]);
    });

    it('a repeated debit for the same revoke moves nothing', async () => {
      const tx = tipTx();
      tx.tipAccount.findUnique.mockResolvedValue({
        id: 'acct-1',
        balanceAtomic: 90_000n,
      });

      await debitBnpTipAccount(tx as never, 'user-1', 35, revokeCtx);
      await expect(
        debitBnpTipAccount(tx as never, 'user-1', 35, revokeCtx),
      ).resolves.toBe(0n);

      expect(tx.tipAccount.updateMany).toHaveBeenCalledTimes(1);
      expect(tx.rows).toHaveLength(1);
    });

    it('debits nothing and writes no row when there is no account', async () => {
      const tx = tipTx();
      tx.tipAccount.findUnique.mockResolvedValue(null);

      await expect(
        debitBnpTipAccount(tx as never, 'user-1', 35, revokeCtx),
      ).resolves.toBe(0n);
      expect(tx.tipAccount.updateMany).not.toHaveBeenCalled();
      expect(tx.tipTransaction.create).not.toHaveBeenCalled();
    });

    it('writes no row when the balance is already empty', async () => {
      const tx = tipTx();
      tx.tipAccount.findUnique.mockResolvedValue({
        id: 'acct-1',
        balanceAtomic: 0n,
      });

      await expect(
        debitBnpTipAccount(tx as never, 'user-1', 35, revokeCtx),
      ).resolves.toBe(0n);
      expect(tx.tipTransaction.create).not.toHaveBeenCalled();
    });
  });
});
