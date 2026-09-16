import { NotificationCategory, NotificationType } from '@prisma/client';
import { NotificationPreferencesService } from '../notifications/notification-preferences.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  createFakeReminderDb,
  type ReminderSessionRow,
} from './mining-reminder.fake';
import { MiningReminderSweepService } from './mining-reminder-sweep.service';

const HOUR = 60 * 60 * 1000;
const NOW = new Date('2026-09-16T12:00:00.000Z');

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

function session(
  overrides: Partial<ReminderSessionRow> & Pick<ReminderSessionRow, 'id'>,
): ReminderSessionRow {
  return {
    userId: 'user-1',
    endsAt: new Date(NOW.getTime() - HOUR),
    claimedAt: null,
    expiredAt: null,
    effectivePointsPerCycle: 126,
    ...overrides,
  };
}

function setup(sessions: ReminderSessionRow[], config = CONFIG) {
  const db = createFakeReminderDb(sessions);
  const fcmService = {
    sendToUsers: jest.fn(async ({ userIds }: { userIds: string[] }) => ({
      sentCount: userIds.length,
      failureCount: 0,
    })),
  };
  const preferences = new NotificationPreferencesService(db.client as any);
  const notifications = new NotificationsService(
    db.client as any,
    { get: jest.fn() } as any,
    { isFollowPrefsEnabled: jest.fn(() => true) } as any,
    preferences,
    { sendCriticalEmail: jest.fn() } as any,
    fcmService as any,
  );
  const miningConfigService = {
    getEffectiveConfig: jest.fn(async () => config),
  };
  const miningExpiryService = {
    expiryCutoff: jest.fn(
      (asOf: Date, cfg: { claimWindowHours: number }) =>
        new Date(asOf.getTime() - cfg.claimWindowHours * HOUR),
    ),
    settleExpiredForUser: jest.fn(async (userId: string) => {
      const cutoff = NOW.getTime() - config.claimWindowHours * HOUR;
      const settled = db.sessions.filter(
        (row) =>
          row.userId === userId &&
          row.claimedAt === null &&
          row.expiredAt === null &&
          row.endsAt.getTime() < cutoff,
      );
      settled.forEach((row) => (row.expiredAt = NOW));
      return settled.map((row) => ({ sessionId: row.id }));
    }),
  };
  const build = () =>
    new MiningReminderSweepService(
      db.client as any,
      miningConfigService as any,
      miningExpiryService as any,
      notifications,
    );

  return {
    db,
    fcmService,
    miningExpiryService,
    sweep: build(),
    build,
  };
}

describe('MiningReminderSweepService', () => {
  it('sends one cycle-ready reminder that deep links to /mining', async () => {
    const { db, fcmService, sweep } = setup([session({ id: 's-1' })]);

    const result = await sweep.sweep(NOW);

    expect(result.readySent).toBe(1);
    expect(result.expiringSent).toBe(0);
    expect(db.notifications).toHaveLength(1);
    expect(db.notifications[0]).toMatchObject({
      userId: 'user-1',
      type: NotificationType.mining_cycle_ready,
      deeplink: '/mining',
      dedupeKey: 'mining.ready:s-1',
    });
    expect(db.notifications[0].title).toBe('126 BNP ready to claim');
    expect(fcmService.sendToUsers).toHaveBeenCalledTimes(1);
    expect(fcmService.sendToUsers.mock.calls[0][0]).toMatchObject({
      userIds: ['user-1'],
      data: expect.objectContaining({
        type: NotificationType.mining_cycle_ready,
        deeplink: '/mining',
        target: '/mining',
        sessionId: 's-1',
      }),
    });
  });

  it('never double-sends across two sweeps', async () => {
    const { db, fcmService, sweep } = setup([
      session({ id: 's-ready' }),
      session({
        id: 's-expiring',
        userId: 'user-2',
        endsAt: new Date(NOW.getTime() - 45 * HOUR),
      }),
    ]);

    await sweep.sweep(NOW);
    const second = await sweep.sweep(new Date(NOW.getTime() + 5 * 60 * 1000));

    expect(second.readySent).toBe(0);
    expect(second.expiringSent).toBe(0);
    expect(db.notifications).toHaveLength(2);
    expect(fcmService.sendToUsers).toHaveBeenCalledTimes(2);
  });

  it('never double-sends when two instances sweep the same sessions', async () => {
    const { db, fcmService, sweep, build } = setup([session({ id: 's-1' })]);
    const otherInstance = build();

    await Promise.all([sweep.sweep(NOW), otherInstance.sweep(NOW)]);

    expect(db.notifications).toHaveLength(1);
    expect(fcmService.sendToUsers).toHaveBeenCalledTimes(1);
  });

  it('sends the expiring reminder once when 6 hours or less remain', async () => {
    const { db, sweep } = setup([
      // deadline = endsAt + 48h = NOW + 3h
      session({ id: 's-1', endsAt: new Date(NOW.getTime() - 45 * HOUR) }),
    ]);

    const first = await sweep.sweep(NOW);
    const second = await sweep.sweep(new Date(NOW.getTime() + HOUR));

    expect(first).toMatchObject({ readySent: 0, expiringSent: 1 });
    expect(second).toMatchObject({ readySent: 0, expiringSent: 0 });
    expect(db.notifications).toHaveLength(1);
    expect(db.notifications[0]).toMatchObject({
      type: NotificationType.mining_claim_expiring,
      dedupeKey: 'mining.expiring:s-1',
      deeplink: '/mining',
    });
    expect(db.notifications[0].title).toContain('126 BNP expires in 3h');
  });

  it('treats exactly 6 hours remaining as expiring and just over as ready', async () => {
    const { db, sweep } = setup([
      session({ id: 's-six', endsAt: new Date(NOW.getTime() - 42 * HOUR) }),
      session({
        id: 's-over',
        userId: 'user-2',
        endsAt: new Date(NOW.getTime() - 42 * HOUR + 1000),
      }),
    ]);

    await sweep.sweep(NOW);

    const byKey = Object.fromEntries(
      db.notifications.map((row) => [row.dedupeKey, row.type]),
    );
    expect(byKey).toEqual({
      'mining.expiring:s-six': NotificationType.mining_claim_expiring,
      'mining.ready:s-over': NotificationType.mining_cycle_ready,
    });
  });

  it('sends ready first, then expiring later, once each', async () => {
    const { db, sweep } = setup([session({ id: 's-1' })]);

    await sweep.sweep(NOW);
    // 43h later: 48h window - 1h already elapsed - 43h = 4h left.
    const later = new Date(NOW.getTime() + 43 * HOUR);
    await sweep.sweep(later);
    await sweep.sweep(new Date(later.getTime() + 5 * 60 * 1000));

    expect(db.notifications.map((row) => row.dedupeKey)).toEqual([
      'mining.ready:s-1',
      'mining.expiring:s-1',
    ]);
    expect(db.notifications[1].title).toContain('expires in 4h');
  });

  it('ignores running, claimed, expired and past-window cycles', async () => {
    const { db, fcmService, sweep } = setup([
      session({ id: 's-running', endsAt: new Date(NOW.getTime() + HOUR) }),
      session({ id: 's-claimed', claimedAt: NOW }),
      session({ id: 's-expired', expiredAt: NOW }),
      session({
        id: 's-past-window',
        endsAt: new Date(NOW.getTime() - 49 * HOUR),
      }),
    ]);

    const result = await sweep.sweep(NOW);

    expect(result).toMatchObject({ readySent: 0, expiringSent: 0 });
    expect(db.notifications).toHaveLength(0);
    expect(fcmService.sendToUsers).not.toHaveBeenCalled();
  });

  it('respects a disabled Mining & Referrals category', async () => {
    const { db, fcmService, sweep } = setup([session({ id: 's-1' })]);
    db.categoryPreferences.push({
      userId: 'user-1',
      category: NotificationCategory.mining_referrals,
      enabled: false,
    });

    await sweep.sweep(NOW);

    expect(db.notifications).toHaveLength(0);
    expect(fcmService.sendToUsers).not.toHaveBeenCalled();
  });

  it('respects the master switch and per-type overrides', async () => {
    const { db, sweep } = setup([
      session({ id: 's-muted' }),
      session({ id: 's-ready-off', userId: 'user-2' }),
      session({
        id: 's-expiring-on',
        userId: 'user-2',
        endsAt: new Date(NOW.getTime() - 45 * HOUR),
      }),
    ]);
    db.settings.push({ userId: 'user-1', masterEnabled: false });
    db.typeOverrides.push({
      userId: 'user-2',
      type: NotificationType.mining_cycle_ready,
      enabled: false,
    });

    await sweep.sweep(NOW);

    expect(db.notifications.map((row) => row.dedupeKey)).toEqual([
      'mining.expiring:s-expiring-on',
    ]);
  });

  it('pages through every candidate in bounded batches', async () => {
    const sessions = ['a', 'b', 'c', 'd', 'e'].map((suffix) =>
      session({ id: `s-${suffix}`, userId: `user-${suffix}` }),
    );
    const { db, sweep } = setup(sessions);

    const result = await sweep.sweep(NOW, { batchSize: 2 });

    expect(result.readySent).toBe(5);
    expect(db.notifications).toHaveLength(5);
    for (const call of db.client.miningSession.findMany.mock.calls) {
      expect(call[0].take).toBeLessThanOrEqual(2);
    }
  });

  it('settles cycles whose window elapsed without the user opening the app', async () => {
    const { db, miningExpiryService, sweep } = setup([
      session({ id: 's-old', endsAt: new Date(NOW.getTime() - 50 * HOUR) }),
      session({
        id: 's-old-2',
        userId: 'user-2',
        endsAt: new Date(NOW.getTime() - 60 * HOUR),
      }),
    ]);

    const result = await sweep.sweep(NOW);

    expect(result.settledCycles).toBe(2);
    expect(miningExpiryService.settleExpiredForUser).toHaveBeenCalledTimes(2);
    expect(db.sessions.every((row) => row.expiredAt !== null)).toBe(true);
    expect(db.notifications).toHaveLength(0);
  });

  it('does not loop forever when a user cannot be settled', async () => {
    const { miningExpiryService, sweep } = setup([
      session({ id: 's-stuck', endsAt: new Date(NOW.getTime() - 50 * HOUR) }),
    ]);
    miningExpiryService.settleExpiredForUser.mockRejectedValue(
      new Error('boom'),
    );

    const result = await sweep.sweep(NOW);

    expect(result.settledCycles).toBe(0);
    expect(miningExpiryService.settleExpiredForUser).toHaveBeenCalledTimes(1);
  });

  it('settles but sends no reminders while mining is disabled', async () => {
    const { db, miningExpiryService, sweep } = setup(
      [
        session({ id: 's-ready' }),
        session({ id: 's-old', endsAt: new Date(NOW.getTime() - 50 * HOUR) }),
      ],
      { ...CONFIG, enabled: false },
    );

    const result = await sweep.sweep(NOW);

    expect(result).toMatchObject({ readySent: 0, expiringSent: 0 });
    expect(db.notifications).toHaveLength(0);
    expect(miningExpiryService.settleExpiredForUser).toHaveBeenCalledTimes(1);
  });
});
