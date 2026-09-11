import { createFakeMiningDb, type FakeSessionRow } from './mining-prisma.fake';
import {
  applyClaimSettlement,
  applyExpirySettlement,
  computeClaimDeadline,
  isClaimWindowExpired,
  isClaimable,
  MiningSessionAlreadySettledError,
  resolveClaimPoints,
} from './mining-settlement';

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
});
