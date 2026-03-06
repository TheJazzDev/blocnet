import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  NotificationCategory,
  NotificationType,
  Prisma,
  RoleName,
  UpdateUrgency,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RuntimeFeatureFlagsService } from '../runtime-flags/runtime-feature-flags.service';
import type { BroadcastTarget } from './dto/broadcast-notification.dto';
import { ListNotificationsQuery } from './dto/list-notifications.query';
import { NotificationEmailService } from './email.service';
import { FcmService } from './fcm.service';
import {
  isCriticalNotificationType,
  NOTIFICATION_TYPES_BY_CATEGORY,
} from './notification-preferences.constants';
import { NotificationPreferencesService } from './notification-preferences.service';
import type {
  NotificationEvent,
  NotifyManyOptions,
} from './types/notification-event.type';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly runtimeFeatureFlagsService: RuntimeFeatureFlagsService,
    private readonly notificationPreferencesService: NotificationPreferencesService,
    private readonly notificationEmailService: NotificationEmailService,
    private readonly fcmService: FcmService,
  ) {}

  async listForUser(userId: string, query: ListNotificationsQuery) {
    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);
    const categoryTypes = this.typesForCategory(query.category);

    return this.prisma.notification.findMany({
      where: {
        userId,
        ...(categoryTypes.length > 0 ? { type: { in: categoryTypes } } : {}),
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
    });
  }

  async markAsRead(userId: string, notificationId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: {
        id: notificationId,
        userId,
      },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    return this.prisma.notification.update({
      where: { id: notificationId },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  async createForProjectFollowers(input: {
    projectId: string;
    updateId: string;
    actorUserId?: string;
    title: string;
    body: string;
    urgency: UpdateUrgency;
  }) {
    const userIds = await this.resolveEligibleFollowerUserIds({
      projectId: input.projectId,
      urgency: input.urgency,
    });

    if (userIds.length === 0) {
      return { insertedCount: 0, userIds };
    }

    const events: NotificationEvent[] = userIds.map((userId) => ({
      userId,
      type: NotificationType.project_update,
      actorUserId: input.actorUserId ?? null,
      projectId: input.projectId,
      updateId: input.updateId,
      urgency: input.urgency,
      title: input.title,
      body: input.body,
      payload: {
        projectId: input.projectId,
        updateId: input.updateId,
        urgency: input.urgency,
      } as Prisma.InputJsonValue,
      deeplink: `/updates/${input.updateId}`,
      pushData: {
        type: NotificationType.project_update,
        projectId: input.projectId,
        updateId: input.updateId,
        urgency: input.urgency,
      },
    }));

    const result = await this.notifyMany(events, { push: false });
    return {
      insertedCount: result.insertedCount,
      userIds: result.insertedUserIds,
    };
  }

  async createBroadcast(input: {
    title: string;
    body: string;
    target: BroadcastTarget;
    userIds?: string[];
  }) {
    const resolvedUserIds = await this.resolveBroadcastUserIds(
      input.target,
      input.userIds,
    );

    if (resolvedUserIds.length === 0) {
      return { insertedCount: 0 };
    }

    const rows = resolvedUserIds.map((userId) => ({
      userId,
      type: NotificationType.system,
      title: input.title,
      body: input.body,
      payload: {
        target: input.target,
      } as Prisma.InputJsonValue,
    }));

    const result = await this.prisma.notification.createMany({
      data: rows,
      skipDuplicates: true,
    });

    return { insertedCount: result.count };
  }

  async resolveBroadcastUserIds(target: BroadcastTarget, userIds?: string[]) {
    if (target === 'specific' && userIds?.length) {
      return [...new Set(userIds)];
    }

    if (target === 'hunters') {
      const roles = await this.prisma.userRole.findMany({
        where: {
          role: {
            in: [RoleName.hunter, RoleName.admin, RoleName.dev, RoleName.owner],
          },
        },
        select: { userId: true },
        distinct: ['userId'],
      });
      return roles.map((row) => row.userId);
    }

    if (target === 'users') {
      const elevated = await this.prisma.userRole.findMany({
        where: {
          role: {
            in: [RoleName.hunter, RoleName.admin, RoleName.dev, RoleName.owner],
          },
        },
        select: { userId: true },
        distinct: ['userId'],
      });
      const elevatedIds = new Set(elevated.map((row) => row.userId));
      const all = await this.prisma.userRole.findMany({
        where: { role: RoleName.user },
        select: { userId: true },
        distinct: ['userId'],
      });
      return all
        .map((row) => row.userId)
        .filter((userId) => !elevatedIds.has(userId));
    }

    const profiles = await this.prisma.profile.findMany({
      where: { isDeactivated: false },
      select: { id: true },
    });
    return profiles.map((profile) => profile.id);
  }

  async resolveBroadcastEmailRecipients(
    target: BroadcastTarget,
    userIds?: string[],
  ) {
    const resolvedUserIds = await this.resolveBroadcastUserIds(target, userIds);
    if (resolvedUserIds.length === 0) {
      return [];
    }

    return this.prisma.profile.findMany({
      where: {
        id: { in: resolvedUserIds },
        isDeactivated: false,
        email: { not: '' },
      },
      select: {
        id: true,
        email: true,
        displayName: true,
        username: true,
      },
    });
  }

  async notifyMany(events: NotificationEvent[], options?: NotifyManyOptions) {
    const pushEnabled = options?.push !== false;
    const normalized = events
      .filter((event) => event.userId.trim().length > 0)
      .filter(
        (event) =>
          !(
            event.skipSelfNotify &&
            event.actorUserId &&
            event.actorUserId === event.userId
          ),
      );

    const { deliverable } =
      await this.notificationPreferencesService.filterEventsByPreference(
        normalized,
      );

    if (deliverable.length === 0) {
      return {
        insertedCount: 0,
        insertedUserIds: [] as string[],
        sentCount: 0,
        failureCount: 0,
      };
    }

    const inserted: NotificationEvent[] = [];
    const withoutDedupe = deliverable.filter(
      (event) => !event.dedupeKey || event.dedupeKey.trim().length === 0,
    );
    const withDedupe = deliverable.filter((event) =>
      Boolean(event.dedupeKey && event.dedupeKey.trim().length > 0),
    );

    if (withoutDedupe.length > 0) {
      const result = await this.prisma.notification.createMany({
        data: withoutDedupe.map((event) => this.toCreateManyInput(event)),
      });

      if (result.count > 0) {
        inserted.push(...withoutDedupe);
      }
    }

    for (const event of withDedupe) {
      const result = await this.prisma.notification.createMany({
        data: [this.toCreateManyInput(event)],
        skipDuplicates: true,
      });
      if (result.count > 0) {
        inserted.push(event);
      }
    }

    const criticalInserted = inserted.filter((event) =>
      isCriticalNotificationType(event.type),
    );
    if (criticalInserted.length > 0) {
      for (const event of criticalInserted) {
        try {
          await this.notificationEmailService.sendCriticalEmail({
            userId: event.userId,
            title: event.title,
            body: event.body,
            deeplink: event.deeplink ?? null,
          });
        } catch (error) {
          this.logger.warn(
            `Failed to deliver critical email for user ${event.userId}: ${
              error instanceof Error ? error.message : String(error)
            }`,
          );
        }
      }
    }

    if (!pushEnabled || inserted.length === 0) {
      return {
        insertedCount: inserted.length,
        insertedUserIds: [...new Set(inserted.map((event) => event.userId))],
        sentCount: 0,
        failureCount: 0,
      };
    }

    const grouped = new Map<
      string,
      {
        userIds: Set<string>;
        title: string;
        body: string;
        data: Record<string, string | number | boolean | null | undefined>;
      }
    >();

    for (const event of inserted) {
      const data = this.toPushData(event);
      const key = this.toPushGroupKey(event.title, event.body, data);
      const existing = grouped.get(key);
      if (existing) {
        existing.userIds.add(event.userId);
        continue;
      }
      grouped.set(key, {
        userIds: new Set([event.userId]),
        title: event.title,
        body: event.body,
        data,
      });
    }

    let sentCount = 0;
    let failureCount = 0;

    for (const group of grouped.values()) {
      const result = await this.fcmService.sendToUsers({
        userIds: [...group.userIds],
        title: group.title,
        body: group.body,
        data: group.data,
      });
      sentCount += result.sentCount;
      failureCount += result.failureCount ?? 0;
    }

    return {
      insertedCount: inserted.length,
      insertedUserIds: [...new Set(inserted.map((event) => event.userId))],
      sentCount,
      failureCount,
    };
  }

  async resolveEligibleFollowerUserIds(input: {
    projectId: string;
    urgency: UpdateUrgency;
  }) {
    const followPrefsEnabled =
      this.runtimeFeatureFlagsService.isFollowPrefsEnabled();
    const follows = await this.prisma.projectFollow.findMany({
      where: { projectId: input.projectId },
      select: {
        userId: true,
        alertMinUrgency: true,
        mutedUntil: true,
      },
    });

    const now = new Date();
    const incomingRank = urgencyRank(input.urgency);
    return follows
      .filter((follow) => {
        if (!followPrefsEnabled) {
          return true;
        }

        if (follow.mutedUntil && follow.mutedUntil > now) {
          return false;
        }

        const requiredRank = urgencyRank(follow.alertMinUrgency);
        return incomingRank >= requiredRank;
      })
      .map((follow) => follow.userId);
  }

  private toCreateManyInput(
    event: NotificationEvent,
  ): Prisma.NotificationCreateManyInput {
    return {
      userId: event.userId,
      type: event.type,
      actorUserId: event.actorUserId ?? null,
      projectId: event.projectId ?? null,
      updateId: event.updateId ?? null,
      urgency: event.urgency ?? null,
      title: event.title,
      body: event.body,
      payload: event.payload ?? undefined,
      deeplink: event.deeplink ?? null,
      dedupeKey: event.dedupeKey ?? null,
    };
  }

  private toPushData(event: NotificationEvent) {
    return {
      type: event.type,
      projectId: event.projectId,
      updateId: event.updateId,
      actorUserId: event.actorUserId,
      deeplink: event.deeplink,
      ...(event.pushData ?? {}),
    };
  }

  private toPushGroupKey(
    title: string,
    body: string,
    data: Record<string, string | number | boolean | null | undefined>,
  ) {
    const dataKey = Object.entries(data)
      .filter(([, value]) => value != null)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([key, value]) => `${key}:${String(value)}`)
      .join('|');
    return `${title}::${body}::${dataKey}`;
  }

  private typesForCategory(
    category?: NotificationCategory,
  ): NotificationType[] {
    if (!category) return [];
    return NOTIFICATION_TYPES_BY_CATEGORY[category] ?? [];
  }
}

function urgencyRank(u: UpdateUrgency): number {
  switch (u) {
    case UpdateUrgency.high:
      return 2;
    case UpdateUrgency.medium:
      return 1;
    case UpdateUrgency.low:
      return 0;
  }
  return 1;
}
