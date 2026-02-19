import { Injectable, NotFoundException } from '@nestjs/common';
import { NotificationType, UpdateUrgency } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ListNotificationsQuery } from './dto/list-notifications.query';
import type { BroadcastTarget } from './dto/broadcast-notification.dto';

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async listForUser(userId: string, query: ListNotificationsQuery) {
    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);

    return this.prisma.notification.findMany({
      where: { userId },
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
    title: string;
    body: string;
    urgency: UpdateUrgency;
  }) {
    const followers = await this.prisma.projectFollow.findMany({
      where: { projectId: input.projectId },
      select: { userId: true },
    });

    if (followers.length === 0) {
      return { insertedCount: 0 };
    }

    const rows = followers.map((follow) => ({
      userId: follow.userId,
      type: NotificationType.project_update,
      projectId: input.projectId,
      updateId: input.updateId,
      urgency: input.urgency,
      title: input.title,
      body: input.body,
    }));

    const result = await this.prisma.notification.createMany({
      data: rows,
      skipDuplicates: true,
    });

    return { insertedCount: result.count };
  }

  async createBroadcast(input: {
    title: string;
    body: string;
    target: BroadcastTarget;
    userIds?: string[];
  }) {
    let resolvedUserIds: string[] = [];

    if (input.target === 'specific' && input.userIds?.length) {
      resolvedUserIds = input.userIds;
    } else if (input.target === 'hunters') {
      const roles = await this.prisma.userRole.findMany({
        where: { role: { in: ['hunter', 'admin', 'owner'] as any } },
        select: { userId: true },
        distinct: ['userId'],
      });
      resolvedUserIds = roles.map((r) => r.userId);
    } else if (input.target === 'users') {
      const elevated = await this.prisma.userRole.findMany({
        where: { role: { in: ['hunter', 'admin', 'owner'] as any } },
        select: { userId: true },
        distinct: ['userId'],
      });
      const elevatedIds = new Set(elevated.map((r) => r.userId));
      const all = await this.prisma.userRole.findMany({
        where: { role: 'user' as any },
        select: { userId: true },
        distinct: ['userId'],
      });
      resolvedUserIds = all
        .map((r) => r.userId)
        .filter((id) => !elevatedIds.has(id));
    } else {
      // 'all'
      const profiles = await this.prisma.profile.findMany({
        select: { id: true },
      });
      resolvedUserIds = profiles.map((p) => p.id);
    }

    if (resolvedUserIds.length === 0) {
      return { insertedCount: 0 };
    }

    const rows = resolvedUserIds.map((userId) => ({
      userId,
      type: NotificationType.system,
      title: input.title,
      body: input.body,
    }));

    const result = await this.prisma.notification.createMany({
      data: rows,
      skipDuplicates: true,
    });

    return { insertedCount: result.count };
  }
}
