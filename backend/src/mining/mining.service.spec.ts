import { AuditLogService } from '../audit-log/audit-log.service';
import { MiningCalculatorService } from './mining-calculator.service';
import { MiningExpiryService } from './mining-expiry.service';
import {
  createFakeMiningDb,
  type FakeCheckpointRow,
  type FakeSessionRow,
} from './mining-prisma.fake';
import { MiningService } from './mining.service';

const CONFIG = {
  enabled: true,
  referralsEnabled: true,
  cycleHours: 24,
  basePointsPerCycle: 120,
  perActiveReferralBoostBps: 500,
  maxBoostBps: 10000,
  activeReferralWindowHours: 168,
  referralBindWindowHours: 24,
  claimWindowHours: 48,
};

const HOUR = 60 * 60 * 1000;

function session(
  overrides: Partial<FakeSessionRow> & Pick<FakeSessionRow, 'startsAt' | 'endsAt'>,
): FakeSessionRow {
  return {
    id: 'session-1',
    userId: 'user-1',
    claimedAt: null,
    expiredAt: null,
    basePointsPerCycle: 120,
    effectivePointsPerCycle: 120,
    boostBpsSnapshot: 0,
    activeReferralsSnapshot: 0,
    ...overrides,
  };
}

function checkpoints(
  sessionId: string,
  count: number,
  points: number,
  startsAt: Date,
): FakeCheckpointRow[] {
  return Array.from({ length: count }, (_, index) => ({
    id: `${sessionId}-cp-${index + 1}`,
    userId: 'user-1',
    sessionId,
    hourIndex: index + 1,
    hourStartAt: new Date(startsAt.getTime() + index * HOUR),
    hourEndAt: new Date(startsAt.getTime() + (index + 1) * HOUR),
    points,
    activeReferralsSnapshot: 0,
    boostBpsSnapshot: 0,
    claimedAt: null,
    expiredAt: null,
  }));
}

describe('MiningService', () => {
  const miningConfigService = { getEffectiveConfig: jest.fn() };
  const auditLogService = { create: jest.fn() };
  const badgesService = { checkMiningMilestones: jest.fn() };
  const questsService = { checkAndCompleteByAction: jest.fn() };
  const levelsService = { updateUserLevel: jest.fn() };

  function buildService(db: ReturnType<typeof createFakeMiningDb>) {
    const expiryService = new MiningExpiryService(
      db.client as never,
      auditLogService as unknown as AuditLogService,
    );

    return new MiningService(
      db.client as never,
      auditLogService as unknown as AuditLogService,
      badgesService as never,
      questsService as never,
      levelsService as never,
      new MiningCalculatorService(),
      miningConfigService as never,
      expiryService,
    );
  }

  beforeEach(() => {
    jest.clearAllMocks();
    miningConfigService.getEffectiveConfig.mockResolvedValue(CONFIG);
    auditLogService.create.mockResolvedValue({});
    badgesService.checkMiningMilestones.mockResolvedValue(undefined);
    questsService.checkAndCompleteByAction.mockResolvedValue(undefined);
    levelsService.updateUserLevel.mockResolvedValue(undefined);
  });

  it('returns existing running session when start is called during active cycle', async () => {
    const now = new Date();
    const db = createFakeMiningDb({
      sessions: [
        session({
          startsAt: new Date(now.getTime() - 2 * HOUR),
          endsAt: new Date(now.getTime() + 22 * HOUR),
        }),
      ],
    });

    const result = await buildService(db).start('user-1');

    expect(result.status).toBe('running');
    expect(db.sessions).toHaveLength(1);
  });

  it('throws claim_required when a still-claimable cycle is outstanding', async () => {
    const now = new Date();
    const db = createFakeMiningDb({
      sessions: [
        session({
          startsAt: new Date(now.getTime() - 26 * HOUR),
          endsAt: new Date(now.getTime() - 2 * HOUR),
        }),
      ],
    });

    await expect(buildService(db).start('user-1')).rejects.toThrow(
      'Claim the previous mining cycle before starting a new one',
    );
    // A cycle inside its window must be left alone, not forfeited.
    expect(db.sessions[0].expiredAt).toBeNull();
  });

  it('claims completed cycle using hourly checkpoint sum and updates balances', async () => {
    const now = new Date();
    const startsAt = new Date(now.getTime() - 26 * HOUR);
    const endsAt = new Date(now.getTime() - 2 * HOUR);
    const db = createFakeMiningDb({
      sessions: [
        session({ startsAt, endsAt, boostBpsSnapshot: 5000, activeReferralsSnapshot: 10 }),
      ],
      checkpoints: checkpoints('session-1', 24, 7, startsAt),
    });

    const result = await buildService(db).claim('user-1');

    expect(result).toEqual(
      expect.objectContaining({ ok: true, status: 'claimed', claimedPoints: 168 }),
    );
    expect(db.sessions[0].claimedAt).not.toBeNull();
    expect(db.sessions[0].expiredAt).toBeNull();
    expect(db.checkpoints.every((row) => row.claimedAt !== null)).toBe(true);
    expect(db.ledger).toEqual([
      expect.objectContaining({ source: 'cycle_claim', points: 168 }),
    ]);
    expect(db.profile.miningClaimedPoints).toBe(168n);
    expect(auditLogService.create).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'mining.claim' }),
    );
    // Auto-starts the next cycle.
    expect(db.sessions).toHaveLength(2);
  });

  describe('F-44 double start', () => {
    function sessionEvents(db: ReturnType<typeof createFakeMiningDb>) {
      return db.events.filter((event) =>
        [
          'tx.begin',
          'executeRaw',
          'lock.acquired',
          'miningSession.findMany',
          'miningSession.create',
          'tx.end',
        ].includes(event.op),
      );
    }

    it('takes the per-user advisory lock, then checks and creates inside one transaction', async () => {
      const db = createFakeMiningDb();

      const result = await buildService(db).start('user-1');

      expect(result.status).toBe('started');
      const createEvent = db.events.find(
        (event) => event.op === 'miningSession.create',
      );
      expect(createEvent?.tx).not.toBeNull();
      const txId = createEvent!.tx;
      const inTx = db.events
        .filter((event) => event.tx === txId)
        .map((event) => event.op);
      expect(inTx).toEqual([
        'tx.begin',
        'executeRaw',
        'lock.acquired',
        'miningSession.findMany',
        'miningSession.create',
        'tx.end',
      ]);
      const lockCall = db.events.find(
        (event) => event.op === 'executeRaw' && event.tx === txId,
      );
      expect(lockCall?.detail).toEqual({
        sql: expect.stringContaining('pg_advisory_xact_lock(hashtext('),
        values: ['user-1'],
      });
      // No session is ever created outside the locked transaction.
      expect(
        sessionEvents(db).filter(
          (event) => event.op === 'miningSession.create' && event.tx === null,
        ),
      ).toHaveLength(0);
    });

    it('two concurrent starts open exactly one session; the second reports running', async () => {
      const db = createFakeMiningDb();
      const service = buildService(db);

      const results = await Promise.all([
        service.start('user-1'),
        service.start('user-1'),
      ]);

      expect(db.sessions).toHaveLength(1);
      expect(results.map((result) => result.status).sort()).toEqual([
        'running',
        'started',
      ]);
      expect(results[0].session.id).toBe(results[1].session.id);
      expect(
        auditLogService.create.mock.calls.filter(
          ([entry]) => entry.action === 'mining.start',
        ),
      ).toHaveLength(1);
    });

    it('auto-start after a claim also creates inside the locked transaction', async () => {
      const now = new Date();
      const startsAt = new Date(now.getTime() - 26 * HOUR);
      const db = createFakeMiningDb({
        sessions: [
          session({ startsAt, endsAt: new Date(now.getTime() - 2 * HOUR) }),
        ],
        checkpoints: checkpoints('session-1', 24, 5, startsAt),
      });

      await buildService(db).claim('user-1');

      const createEvents = db.events.filter(
        (event) => event.op === 'miningSession.create',
      );
      expect(createEvents).toHaveLength(1);
      const txId = createEvents[0].tx;
      expect(txId).not.toBeNull();
      expect(
        db.events
          .filter((event) => event.tx === txId)
          .map((event) => event.op),
      ).toEqual([
        'tx.begin',
        'executeRaw',
        'lock.acquired',
        'miningSession.findMany',
        'miningSession.create',
        'tx.end',
      ]);
    });
  });

  describe('F-45 concurrent hourly accrual', () => {
    it('two concurrent getMe calls write each hourly checkpoint once and never throw', async () => {
      const now = new Date();
      const db = createFakeMiningDb({
        sessions: [
          session({
            startsAt: new Date(now.getTime() - 5 * HOUR - 60_000),
            endsAt: new Date(now.getTime() + 19 * HOUR - 60_000),
          }),
        ],
      });
      const service = buildService(db);

      await expect(
        Promise.all([service.getMe('user-1'), service.getMe('user-1')]),
      ).resolves.toHaveLength(2);

      expect(db.checkpoints.map((row) => row.hourIndex).sort()).toEqual([
        1, 2, 3, 4, 5,
      ]);
    });
  });

  describe('F-48 cycle total', () => {
    it('accrues and claims exactly the projected cycle points when base does not divide evenly', async () => {
      const now = new Date();
      const startsAt = new Date(now.getTime() - 26 * HOUR);
      const db = createFakeMiningDb({
        sessions: [
          session({
            startsAt,
            endsAt: new Date(now.getTime() - 2 * HOUR),
            basePointsPerCycle: 125,
            effectivePointsPerCycle: 125,
          }),
        ],
      });

      const result = await buildService(db).claim('user-1');

      expect(db.checkpoints).toHaveLength(24);
      expect(result).toEqual(
        expect.objectContaining({ status: 'claimed', claimedPoints: 125 }),
      );
    });
  });

  describe('F-50 boost uses the shared active-referral rule', () => {
    it('counts referrals by mining start, not feed visits', async () => {
      const db = createFakeMiningDb();

      await buildService(db).start('user-1');

      const whereClauses = db.client.profile.count.mock.calls.map(
        ([args]: any) => args?.where,
      );
      expect(whereClauses.length).toBeGreaterThan(0);
      for (const where of whereClauses) {
        expect(where).not.toHaveProperty('homeFeedLastSeenAt');
        expect(where).toEqual({
          referredById: 'user-1',
          miningSessions: {
            some: { startsAt: { gte: expect.any(Date), lte: expect.any(Date) } },
          },
        });
      }
    });
  });

  describe('F-51 mining paused (config.enabled=false)', () => {
    const PAUSED = { ...CONFIG, enabled: false, referralsEnabled: false };

    beforeEach(() => {
      miningConfigService.getEffectiveConfig.mockResolvedValue(PAUSED);
    });

    it('blocks a manual start', async () => {
      const db = createFakeMiningDb();

      await expect(buildService(db).start('user-1')).rejects.toThrow(
        'Mining is disabled',
      );
      expect(db.sessions).toHaveLength(0);
    });

    it('still pays a completed cycle but does not auto-start the next one', async () => {
      const now = new Date();
      const startsAt = new Date(now.getTime() - 26 * HOUR);
      const db = createFakeMiningDb({
        sessions: [
          session({ startsAt, endsAt: new Date(now.getTime() - 2 * HOUR) }),
        ],
        checkpoints: checkpoints('session-1', 24, 5, startsAt),
      });

      const result = await buildService(db).claim('user-1');

      expect(result).toEqual(
        expect.objectContaining({
          status: 'claimed',
          claimedPoints: 120,
          nextSession: null,
        }),
      );
      expect(db.profile.miningClaimedPoints).toBe(120n);
      expect(db.sessions).toHaveLength(1);
    });

    it('does not auto-start after a forfeited cycle either', async () => {
      const now = new Date();
      const startsAt = new Date(now.getTime() - 100 * HOUR);
      const db = createFakeMiningDb({
        sessions: [
          session({ startsAt, endsAt: new Date(now.getTime() - 76 * HOUR) }),
        ],
      });

      const result = await buildService(db).claim('user-1');

      expect(result).toEqual(
        expect.objectContaining({ status: 'expired', nextSession: null }),
      );
      expect(db.sessions).toHaveLength(1);
    });

    it('getMe reports config.enabled=false so clients can show a paused state', async () => {
      const db = createFakeMiningDb();

      const snapshot = await buildService(db).getMe('user-1');

      expect(snapshot.config.enabled).toBe(false);
      expect(snapshot.session.status).toBe('idle');
    });
  });

  describe('F-39 claim-window deadlock', () => {
    function deadlockedDb() {
      const now = new Date();
      const startsAt = new Date(now.getTime() - 100 * HOUR);
      const endsAt = new Date(now.getTime() - 76 * HOUR); // 76h > 48h window
      return createFakeMiningDb({
        sessions: [session({ startsAt, endsAt })],
        checkpoints: checkpoints('session-1', 24, 5, startsAt),
      });
    }

    it('start() settles the expired cycle instead of refusing forever', async () => {
      const db = deadlockedDb();

      const result = await buildService(db).start('user-1');

      expect(result.status).toBe('started');
      expect(result.expiredCycles).toEqual([
        expect.objectContaining({ sessionId: 'session-1', forfeitedPoints: 120 }),
      ]);
      expect(db.sessions[0].expiredAt).not.toBeNull();
      expect(db.sessions[0].claimedAt).toBeNull();
      expect(db.checkpoints.every((row) => row.expiredAt !== null)).toBe(true);
      expect(db.sessions).toHaveLength(2);
      expect(auditLogService.create).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'mining.cycle.expired' }),
      );
    });

    it('claim() forfeits rather than dead-ending, and pays nothing', async () => {
      const db = deadlockedDb();

      const result = await buildService(db).claim('user-1');

      expect(result).toEqual(
        expect.objectContaining({
          ok: false,
          status: 'expired',
          code: 'claim_window_expired',
          claimedPoints: 0,
          forfeitedPoints: 120,
        }),
      );
      expect(db.ledger).toHaveLength(0);
      expect(db.profile.miningClaimedPoints).toBe(0n);
      expect(db.sessions[0].expiredAt).not.toBeNull();
      // The account is unwedged: a fresh cycle is open.
      expect(db.sessions).toHaveLength(2);
    });

    it('a second start() after settlement is a normal no-op start', async () => {
      const db = deadlockedDb();
      const service = buildService(db);

      await service.start('user-1');
      const second = await service.start('user-1');

      expect(second.status).toBe('running');
      expect(second.expiredCycles).toEqual([]);
      expect(db.sessions).toHaveLength(2);
    });

    it('getMe() reports idle instead of advertising unclaimable points', async () => {
      const db = deadlockedDb();

      const snapshot = await buildService(db).getMe('user-1');

      expect(snapshot.session.status).toBe('idle');
      expect(snapshot.balance.maturedUnclaimedPoints).toBe(0);
      expect(snapshot.lastExpiredCycle).toEqual(
        expect.objectContaining({ sessionId: 'session-1', forfeitedPoints: 120 }),
      );
      expect(
        snapshot.hourlyHistory.every((row) => row.status === 'expired'),
      ).toBe(true);
    });

    it('leaves a cycle inside its window claimable', async () => {
      const now = new Date();
      const startsAt = new Date(now.getTime() - 30 * HOUR);
      const endsAt = new Date(now.getTime() - 6 * HOUR); // 6h < 48h window
      const db = createFakeMiningDb({
        sessions: [session({ startsAt, endsAt })],
        checkpoints: checkpoints('session-1', 24, 5, startsAt),
      });

      const snapshot = await buildService(db).getMe('user-1');

      expect(snapshot.session.status).toBe('claimable');
      expect(snapshot.balance.maturedUnclaimedPoints).toBe(120);
      expect(snapshot.lastExpiredCycle).toBeNull();
      expect(db.sessions[0].expiredAt).toBeNull();
    });
  });
});
