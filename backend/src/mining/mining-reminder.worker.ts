import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DatabaseHealthService } from '../prisma/database-health.service';
import {
  DEFAULT_MINING_REMINDER_BATCH_SIZE,
  MiningReminderSweepService,
} from './mining-reminder-sweep.service';

export const MINING_REMINDER_INTERVAL_MS = 5 * 60 * 1000;
const WARM_START_DELAY_MS = 15_000;

/**
 * Runs the mining reminder sweep every 5 minutes (F-49). Mirrors
 * `NotificationDigestWorker`: a config kill switch, a single-flight guard and
 * a database health check. Never scheduled under Jest (`NODE_ENV=test`), and
 * specs construct the sweep directly.
 */
@Injectable()
export class MiningReminderWorker implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(MiningReminderWorker.name);

  private timer: NodeJS.Timeout | null = null;
  private warmStart: NodeJS.Timeout | null = null;
  private isRunning = false;
  private lastDbUnavailableLogAt = 0;

  constructor(
    private readonly configService: ConfigService,
    private readonly databaseHealthService: DatabaseHealthService,
    private readonly sweepService: MiningReminderSweepService,
  ) {}

  onModuleInit() {
    if (process.env.NODE_ENV === 'test') {
      return;
    }

    if (!this.configService.get<boolean>('MINING_REMINDERS_ENABLED', true)) {
      this.logger.log(
        'Mining reminder worker disabled by MINING_REMINDERS_ENABLED=false',
      );
      return;
    }

    this.timer = setInterval(() => {
      void this.runTickSafely();
    }, MINING_REMINDER_INTERVAL_MS);

    this.warmStart = setTimeout(() => {
      void this.runTickSafely();
    }, WARM_START_DELAY_MS);
  }

  onModuleDestroy() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
    if (this.warmStart) {
      clearTimeout(this.warmStart);
      this.warmStart = null;
    }
  }

  async tick() {
    if (this.isRunning) {
      this.logger.warn(
        'Skipping mining reminder tick because previous run is still active',
      );
      return;
    }

    this.isRunning = true;
    try {
      const databaseHealthy =
        await this.databaseHealthService.isDatabaseHealthy();
      if (!databaseHealthy) {
        this.logDbUnavailableSkip();
        return;
      }

      await this.sweepService.sweep(new Date(), {
        batchSize: this.configService.get<number>(
          'MINING_REMINDER_BATCH_SIZE',
          DEFAULT_MINING_REMINDER_BATCH_SIZE,
        ),
      });
    } catch (error) {
      this.logger.error(
        `Mining reminder tick failed: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    } finally {
      this.isRunning = false;
    }
  }

  private async runTickSafely(): Promise<void> {
    try {
      await this.tick();
    } catch (error) {
      this.logger.error(
        `Mining reminder tick rejected unexpectedly: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }

  private logDbUnavailableSkip() {
    const now = Date.now();
    if (now - this.lastDbUnavailableLogAt < 60_000) {
      return;
    }
    this.lastDbUnavailableLogAt = now;
    this.logger.warn(
      'Skipping mining reminder tick because database is unavailable.',
    );
  }
}
