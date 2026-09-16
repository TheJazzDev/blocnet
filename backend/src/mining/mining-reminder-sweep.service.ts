import { Injectable, Logger } from '@nestjs/common';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import type { EffectiveMiningConfig } from './mining-calculator.service';
import { MiningConfigService } from './mining-config.service';
import { MiningExpiryService } from './mining-expiry.service';
import { computeClaimDeadline } from './mining-settlement';
import {
  buildReminderEvent,
  reminderDedupeKey,
  reminderKindFor,
  type ReminderCandidate,
  type ReminderKind,
} from './mining-reminder.messages';

export const DEFAULT_MINING_REMINDER_BATCH_SIZE = 200;

/** Upper bound on expiry batches per sweep; the next sweep picks up the rest. */
const MAX_EXPIRY_BATCHES = 50;

export type MiningReminderSweepResult = {
  readySent: number;
  expiringSent: number;
  settledCycles: number;
};

export type MiningReminderSweepOptions = {
  batchSize?: number;
};

const UNSETTLED = { claimedAt: null, expiredAt: null } as const;

type DueReminder = {
  kind: ReminderKind;
  dedupeKey: string;
  candidate: ReminderCandidate;
};

/**
 * One pass of the mining reminder sweep (F-49):
 *
 *  1. settle cycles whose claim window elapsed, so forfeits no longer wait for
 *     the member to open the app;
 *  2. send "cycle ready" once per ended, claimable cycle;
 *  3. send "claim expiring" once when 6 hours or less of the window remain.
 *
 * Once-only delivery rests on `Notification @@unique([userId, dedupeKey])`:
 * already-sent keys are skipped up front, and `notifyMany` inserts with
 * `skipDuplicates` and pushes only rows it actually inserted, so restarts and
 * concurrent instances cannot double-send.
 */
@Injectable()
export class MiningReminderSweepService {
  private readonly logger = new Logger(MiningReminderSweepService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly miningConfigService: MiningConfigService,
    private readonly miningExpiryService: MiningExpiryService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async sweep(
    asOf: Date,
    options: MiningReminderSweepOptions = {},
  ): Promise<MiningReminderSweepResult> {
    const batchSize = Math.max(
      1,
      options.batchSize ?? DEFAULT_MINING_REMINDER_BATCH_SIZE,
    );
    const config = await this.miningConfigService.getEffectiveConfig();

    const settledCycles = await this.settleExpired(asOf, config, batchSize);

    if (!config.enabled) {
      return { readySent: 0, expiringSent: 0, settledCycles };
    }

    const sent = await this.sendReminders(asOf, config, batchSize);
    return { ...sent, settledCycles };
  }

  private async settleExpired(
    asOf: Date,
    config: EffectiveMiningConfig,
    batchSize: number,
  ): Promise<number> {
    const cutoff = this.miningExpiryService.expiryCutoff(asOf, config);
    const attempted = new Set<string>();
    let settledCycles = 0;

    for (let batch = 0; batch < MAX_EXPIRY_BATCHES; batch += 1) {
      const rows = await this.prisma.miningSession.findMany({
        where: {
          ...UNSETTLED,
          endsAt: { lt: cutoff },
          ...(attempted.size > 0 ? { userId: { notIn: [...attempted] } } : {}),
        },
        distinct: ['userId'],
        select: { userId: true },
        take: batchSize,
      });

      if (rows.length === 0) {
        break;
      }

      for (const { userId } of rows) {
        attempted.add(userId);
        try {
          const forfeited = await this.miningExpiryService.settleExpiredForUser(
            userId,
            asOf,
            config,
          );
          settledCycles += forfeited.length;
        } catch (error) {
          this.logger.warn(
            `Expiry settlement failed for user ${userId}: ${errorMessage(error)}`,
          );
        }
      }
    }

    return settledCycles;
  }

  private async sendReminders(
    asOf: Date,
    config: EffectiveMiningConfig,
    batchSize: number,
  ): Promise<Omit<MiningReminderSweepResult, 'settledCycles'>> {
    const cutoff = this.miningExpiryService.expiryCutoff(asOf, config);
    let readySent = 0;
    let expiringSent = 0;
    let cursor: string | undefined;

    while (true) {
      const sessions = await this.prisma.miningSession.findMany({
        where: {
          ...UNSETTLED,
          // Ended, and the window (endsAt + claimWindowHours) still open.
          endsAt: { lte: asOf, gte: cutoff },
        },
        orderBy: { id: 'asc' },
        take: batchSize,
        ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
        select: {
          id: true,
          userId: true,
          endsAt: true,
          effectivePointsPerCycle: true,
        },
      });

      if (sessions.length === 0) {
        break;
      }
      cursor = sessions[sessions.length - 1].id;

      const due = sessions.map((session): DueReminder => {
        const claimDeadline = computeClaimDeadline(session.endsAt, config);
        const kind = reminderKindFor(claimDeadline, asOf);
        return {
          kind,
          dedupeKey: reminderDedupeKey(kind, session.id),
          candidate: {
            sessionId: session.id,
            userId: session.userId,
            points: session.effectivePointsPerCycle,
            claimDeadline,
          },
        };
      });

      const alreadySent = await this.prisma.notification.findMany({
        where: {
          userId: {
            in: [...new Set(due.map((item) => item.candidate.userId))],
          },
          dedupeKey: { in: due.map((item) => item.dedupeKey) },
        },
        select: { userId: true, dedupeKey: true },
      });
      const sentKeys = new Set(
        alreadySent.map((row) => `${row.userId}::${row.dedupeKey}`),
      );

      const pending = due.filter(
        (item) => !sentKeys.has(`${item.candidate.userId}::${item.dedupeKey}`),
      );

      readySent += await this.notify(pending, 'ready', asOf);
      expiringSent += await this.notify(pending, 'expiring', asOf);

      if (sessions.length < batchSize) {
        break;
      }
    }

    if (readySent + expiringSent > 0) {
      this.logger.log(
        `Mining reminders sent: ${readySent} ready, ${expiringSent} expiring`,
      );
    }

    return { readySent, expiringSent };
  }

  /** Sends one kind per call so the inserted count maps to that kind. */
  private async notify(
    pending: DueReminder[],
    kind: ReminderKind,
    asOf: Date,
  ): Promise<number> {
    const events = pending
      .filter((item) => item.kind === kind)
      .map((item) => buildReminderEvent(kind, item.candidate, asOf));
    if (events.length === 0) {
      return 0;
    }

    try {
      const result = await this.notificationsService.notifyMany(events);
      return result.insertedCount;
    } catch (error) {
      this.logger.warn(
        `Mining ${kind} reminder batch failed: ${errorMessage(error)}`,
      );
      return 0;
    }
  }
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : String(error);
}
