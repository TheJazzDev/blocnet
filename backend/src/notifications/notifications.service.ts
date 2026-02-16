import { Injectable, NotFoundException } from '@nestjs/common';
import { NotificationType, PostUrgency } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ListNotificationsQuery } from './dto/list-notifications.query';

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
    postId: string;
    title: string;
    body: string;
    urgency: PostUrgency;
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
      postId: input.postId,
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
}
