import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  DigestCadence,
  NotificationCategory,
  NotificationType,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  DEFAULT_DIGEST_HOUR_LOCAL,
  DEFAULT_DIGEST_MINUTE_LOCAL,
  DEFAULT_TIMEZONE,
  NOTIFICATION_CATEGORY_LABELS,
  NOTIFICATION_CATEGORY_ORDER,
  NOTIFICATION_TYPES_BY_CATEGORY,
  NOTIFICATION_TYPE_TO_CATEGORY,
  isCriticalNotificationType,
} from './notification-preferences.constants';
import { UpdateNotificationPreferencesDto } from './dto/update-notification-preferences.dto';
import type { NotificationEvent } from './types/notification-event.type';
import { isValidIanaTimezone } from './utils/timezone.util';

type PreferenceSnapshot = {
  masterEnabled: boolean;
  digestEmailEnabled: boolean;
  digestCadence: DigestCadence;
  digestHourLocal: number;
  digestMinuteLocal: number;
  timezone: string;
  lastDigestSentAt: Date | null;
  categories: Map<NotificationCategory, boolean>;
  typeOverrides: Map<NotificationType, boolean>;
};

@Injectable()
export class NotificationPreferencesService {
  constructor(private readonly prisma: PrismaService) {}

  async getCatalog() {
    return {
      categories: NOTIFICATION_CATEGORY_ORDER.map((category) => ({
        key: category,
        label: NOTIFICATION_CATEGORY_LABELS[category],
        types: NOTIFICATION_TYPES_BY_CATEGORY[category],
      })),
      criticalTypes: [
        ...new Set(
          Object.values(NotificationType).filter(isCriticalNotificationType),
        ),
      ],
    };
  }

  async getPreferences(userId: string) {
    await this.assertUserExists(userId);
    const map = await this.loadPreferenceSnapshots([userId]);
    return this.toPreferenceResponse(
      map.get(userId) ?? this.createDefaultSnapshot(),
    );
  }

  async updatePreferences(
    userId: string,
    dto: UpdateNotificationPreferencesDto,
  ) {
    await this.assertUserExists(userId);

    if (dto.timezone !== undefined && !isValidIanaTimezone(dto.timezone)) {
      throw new BadRequestException('timezone must be a valid IANA timezone');
    }

    await this.prisma.$transaction(async (tx) => {
      const hasSettingsMutation =
        dto.masterEnabled !== undefined ||
        dto.digestEmailEnabled !== undefined ||
        dto.digestCadence !== undefined ||
        dto.digestHourLocal !== undefined ||
        dto.digestMinuteLocal !== undefined ||
        dto.timezone !== undefined;

      if (hasSettingsMutation) {
        const data: Prisma.UserNotificationSettingsUncheckedCreateInput = {
          userId,
          masterEnabled: dto.masterEnabled ?? true,
          digestEmailEnabled: dto.digestEmailEnabled ?? true,
          digestCadence: dto.digestCadence ?? DigestCadence.daily,
          digestHourLocal: dto.digestHourLocal ?? DEFAULT_DIGEST_HOUR_LOCAL,
          digestMinuteLocal:
            dto.digestMinuteLocal ?? DEFAULT_DIGEST_MINUTE_LOCAL,
          timezone: dto.timezone ?? DEFAULT_TIMEZONE,
        };

        await tx.userNotificationSettings.upsert({
          where: { userId },
          create: data,
          update: {
            masterEnabled: dto.masterEnabled,
            digestEmailEnabled: dto.digestEmailEnabled,
            digestCadence: dto.digestCadence,
            digestHourLocal: dto.digestHourLocal,
            digestMinuteLocal: dto.digestMinuteLocal,
            timezone: dto.timezone,
          },
        });
      }

      if (dto.categories?.length) {
        for (const item of dto.categories) {
          await tx.userNotificationCategoryPreference.upsert({
            where: {
              userId_category: {
                userId,
                category: item.category,
              },
            },
            create: {
              userId,
              category: item.category,
              enabled: item.enabled,
            },
            update: {
              enabled: item.enabled,
            },
          });
        }
      }

      if (dto.typeOverrides?.length) {
        for (const item of dto.typeOverrides) {
          await tx.userNotificationTypeOverride.upsert({
            where: {
              userId_type: {
                userId,
                type: item.type,
              },
            },
            create: {
              userId,
              type: item.type,
              enabled: item.enabled,
            },
            update: {
              enabled: item.enabled,
            },
          });
        }
      }

      if (dto.clearTypeOverrides?.length) {
        await tx.userNotificationTypeOverride.deleteMany({
          where: {
            userId,
            type: {
              in: [...new Set(dto.clearTypeOverrides)],
            },
          },
        });
      }
    });

    return this.getPreferences(userId);
  }

  async filterEventsByPreference(events: NotificationEvent[]) {
    if (events.length === 0) {
      return {
        deliverable: [] as NotificationEvent[],
        suppressed: [] as NotificationEvent[],
      };
    }

    const userIds = [...new Set(events.map((event) => event.userId))];
    const snapshots = await this.loadPreferenceSnapshots(userIds);
    const deliverable: NotificationEvent[] = [];
    const suppressed: NotificationEvent[] = [];

    for (const event of events) {
      if (isCriticalNotificationType(event.type)) {
        deliverable.push(event);
        continue;
      }

      const snapshot =
        snapshots.get(event.userId) ?? this.createDefaultSnapshot();
      if (!snapshot.masterEnabled) {
        suppressed.push(event);
        continue;
      }

      const typeOverride = snapshot.typeOverrides.get(event.type);
      if (typeOverride !== undefined) {
        if (typeOverride) {
          deliverable.push(event);
        } else {
          suppressed.push(event);
        }
        continue;
      }

      const category =
        NOTIFICATION_TYPE_TO_CATEGORY[event.type] ??
        NotificationCategory.system;
      const categoryEnabled = snapshot.categories.get(category);
      if (categoryEnabled === false) {
        suppressed.push(event);
        continue;
      }

      deliverable.push(event);
    }

    return {
      deliverable,
      suppressed,
    };
  }

  private async assertUserExists(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }
  }

  private createDefaultSnapshot(): PreferenceSnapshot {
    return {
      masterEnabled: true,
      digestEmailEnabled: true,
      digestCadence: DigestCadence.daily,
      digestHourLocal: DEFAULT_DIGEST_HOUR_LOCAL,
      digestMinuteLocal: DEFAULT_DIGEST_MINUTE_LOCAL,
      timezone: DEFAULT_TIMEZONE,
      lastDigestSentAt: null,
      categories: new Map(
        NOTIFICATION_CATEGORY_ORDER.map((category) => [category, true]),
      ),
      typeOverrides: new Map(),
    };
  }

  private toPreferenceResponse(snapshot: PreferenceSnapshot) {
    const categories = NOTIFICATION_CATEGORY_ORDER.reduce(
      (acc, category) => {
        acc[category] = snapshot.categories.get(category) ?? true;
        return acc;
      },
      {} as Record<NotificationCategory, boolean>,
    );

    const typeOverrides = [...snapshot.typeOverrides.entries()].reduce(
      (acc, [type, enabled]) => {
        acc[type] = enabled;
        return acc;
      },
      {} as Record<string, boolean>,
    );

    return {
      masterEnabled: snapshot.masterEnabled,
      digestEmailEnabled: snapshot.digestEmailEnabled,
      digestCadence: snapshot.digestCadence,
      digestHourLocal: snapshot.digestHourLocal,
      digestMinuteLocal: snapshot.digestMinuteLocal,
      timezone: snapshot.timezone,
      categories,
      typeOverrides,
      criticalTypes: [
        ...Object.values(NotificationType).filter(isCriticalNotificationType),
      ],
    };
  }

  private async loadPreferenceSnapshots(userIds: string[]) {
    if (userIds.length === 0) {
      return new Map<string, PreferenceSnapshot>();
    }

    const [settings, categoryRows, overrideRows] = await Promise.all([
      this.prisma.userNotificationSettings.findMany({
        where: { userId: { in: userIds } },
        select: {
          userId: true,
          masterEnabled: true,
          digestEmailEnabled: true,
          digestCadence: true,
          digestHourLocal: true,
          digestMinuteLocal: true,
          timezone: true,
          lastDigestSentAt: true,
        },
      }),
      this.prisma.userNotificationCategoryPreference.findMany({
        where: { userId: { in: userIds } },
        select: {
          userId: true,
          category: true,
          enabled: true,
        },
      }),
      this.prisma.userNotificationTypeOverride.findMany({
        where: { userId: { in: userIds } },
        select: {
          userId: true,
          type: true,
          enabled: true,
        },
      }),
    ]);

    const map = new Map<string, PreferenceSnapshot>();

    for (const userId of userIds) {
      map.set(userId, this.createDefaultSnapshot());
    }

    for (const row of settings) {
      map.set(row.userId, {
        ...(map.get(row.userId) ?? this.createDefaultSnapshot()),
        masterEnabled: row.masterEnabled,
        digestEmailEnabled: row.digestEmailEnabled,
        digestCadence: row.digestCadence,
        digestHourLocal: row.digestHourLocal,
        digestMinuteLocal: row.digestMinuteLocal,
        timezone: row.timezone,
        lastDigestSentAt: row.lastDigestSentAt,
      });
    }

    for (const row of categoryRows) {
      const snapshot = map.get(row.userId) ?? this.createDefaultSnapshot();
      snapshot.categories.set(row.category, row.enabled);
      map.set(row.userId, snapshot);
    }

    for (const row of overrideRows) {
      const snapshot = map.get(row.userId) ?? this.createDefaultSnapshot();
      snapshot.typeOverrides.set(row.type, row.enabled);
      map.set(row.userId, snapshot);
    }

    return map;
  }
}
