import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DigestCadence } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UserDigestService } from '../users/user-digest.service';
import {
  DEFAULT_DIGEST_HOUR_LOCAL,
  DEFAULT_DIGEST_MINUTE_LOCAL,
  DEFAULT_TIMEZONE,
} from './notification-preferences.constants';
import { DigestComposerService } from './digest-composer.service';
import { NotificationEmailService } from './email.service';
import {
  isValidIanaTimezone,
  localDateKey,
  localMinuteOfDay,
} from './utils/timezone.util';

@Injectable()
export class NotificationDigestWorker implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(NotificationDigestWorker.name);

  private timer: NodeJS.Timeout | null = null;
  private isRunning = false;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
    private readonly userDigestService: UserDigestService,
    private readonly digestComposer: DigestComposerService,
    private readonly emailService: NotificationEmailService,
  ) {}

  onModuleInit() {
    if (!this.configService.get<boolean>('NOTIFICATION_DIGEST_ENABLED', true)) {
      this.logger.log(
        'Digest worker disabled by NOTIFICATION_DIGEST_ENABLED=false',
      );
      return;
    }

    const intervalMs = 5 * 60 * 1000;
    this.timer = setInterval(() => {
      void this.tick();
    }, intervalMs);

    // Warm start once after boot.
    setTimeout(() => {
      void this.tick();
    }, 10_000);
  }

  onModuleDestroy() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  async tick() {
    if (this.isRunning) {
      this.logger.warn(
        'Skipping digest tick because previous run is still active',
      );
      return;
    }

    this.isRunning = true;
    const now = new Date();

    try {
      const sendWindowMinutes = this.configService.get<number>(
        'NOTIFICATION_DIGEST_SEND_WINDOW_MINUTES',
        10,
      );
      const batchSize = this.configService.get<number>(
        'NOTIFICATION_DIGEST_BATCH_SIZE',
        200,
      );

      let cursor: string | undefined;
      while (true) {
        const profiles = await this.prisma.profile.findMany({
          where: {
            isDeactivated: false,
          },
          orderBy: { id: 'asc' },
          take: Math.max(10, batchSize),
          ...(cursor
            ? {
                cursor: { id: cursor },
                skip: 1,
              }
            : {}),
          select: {
            id: true,
            email: true,
            displayName: true,
            username: true,
            notificationSettings: {
              select: {
                digestEmailEnabled: true,
                digestCadence: true,
                digestHourLocal: true,
                digestMinuteLocal: true,
                timezone: true,
                lastDigestSentAt: true,
              },
            },
          },
        });

        if (profiles.length === 0) {
          break;
        }

        for (const profile of profiles) {
          try {
            if (!profile.email?.trim()) {
              continue;
            }

            const settings = profile.notificationSettings;
            const digestEnabled = settings?.digestEmailEnabled ?? true;
            if (!digestEnabled) {
              continue;
            }

            const cadence = settings?.digestCadence ?? DigestCadence.daily;
            const timezone =
              settings?.timezone && isValidIanaTimezone(settings.timezone)
                ? settings.timezone
                : DEFAULT_TIMEZONE;

            const hour = settings?.digestHourLocal ?? DEFAULT_DIGEST_HOUR_LOCAL;
            const minute =
              settings?.digestMinuteLocal ?? DEFAULT_DIGEST_MINUTE_LOCAL;
            if (
              !this.isWithinDispatchWindow({
                now,
                timezone,
                targetHour: hour,
                targetMinute: minute,
                sendWindowMinutes,
              })
            ) {
              continue;
            }

            if (
              this.wasSentInCurrentWindow({
                lastSentAt: settings?.lastDigestSentAt ?? null,
                now,
                timezone,
                cadence,
              })
            ) {
              continue;
            }

            const windowDays = cadence === DigestCadence.daily ? 1 : 7;
            const summary = await this.userDigestService.getDigestSummary(
              profile.id,
              windowDays,
              { skipAudit: true },
            );

            const composed = this.digestComposer.compose({
              recipient: {
                email: profile.email,
                displayName: profile.displayName,
                username: profile.username,
              },
              cadence: cadence === DigestCadence.weekly ? 'weekly' : 'daily',
              windowDays,
              summary: {
                missedHighUrgency: summary.missedHighUrgency,
                activeProjects: summary.activeProjects,
                topCommunityPosts: summary.topCommunityPosts,
              },
              asOf: now,
            });

            if (!composed.hasContent) {
              continue;
            }

            const emailResult = await this.emailService.sendDigestEmail({
              to: profile.email,
              subject: composed.subject,
              html: composed.html,
              text: composed.text,
            });

            if (!emailResult.delivered) {
              continue;
            }

            await this.prisma.userNotificationSettings.upsert({
              where: { userId: profile.id },
              create: {
                userId: profile.id,
                digestEmailEnabled: true,
                digestCadence: cadence,
                digestHourLocal: hour,
                digestMinuteLocal: minute,
                timezone,
                lastDigestSentAt: now,
              },
              update: {
                lastDigestSentAt: now,
              },
            });
          } catch (error) {
            this.logger.warn(
              `Digest send failed for user ${profile.id}: ${
                error instanceof Error ? error.message : String(error)
              }`,
            );
          }
        }

        cursor = profiles[profiles.length - 1]?.id;
      }
    } finally {
      this.isRunning = false;
    }
  }

  private isWithinDispatchWindow(input: {
    now: Date;
    timezone: string;
    targetHour: number;
    targetMinute: number;
    sendWindowMinutes: number;
  }) {
    const minuteOfDay = localMinuteOfDay(input.now, input.timezone);
    const targetMinuteOfDay = input.targetHour * 60 + input.targetMinute;
    const windowEnd = targetMinuteOfDay + Math.max(1, input.sendWindowMinutes);

    if (windowEnd < 24 * 60) {
      return minuteOfDay >= targetMinuteOfDay && minuteOfDay < windowEnd;
    }

    return (
      minuteOfDay >= targetMinuteOfDay || minuteOfDay < windowEnd - 24 * 60
    );
  }

  private wasSentInCurrentWindow(input: {
    lastSentAt: Date | null;
    now: Date;
    timezone: string;
    cadence: DigestCadence;
  }) {
    if (!input.lastSentAt) {
      return false;
    }

    if (input.cadence === DigestCadence.daily) {
      return (
        localDateKey(input.lastSentAt, input.timezone) ===
        localDateKey(input.now, input.timezone)
      );
    }

    const diffMs = input.now.getTime() - input.lastSentAt.getTime();
    return diffMs < 7 * 24 * 60 * 60 * 1000;
  }
}
