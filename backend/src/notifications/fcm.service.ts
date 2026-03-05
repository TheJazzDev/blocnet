import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RoleName } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { App, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import type { BroadcastTarget } from './dto/broadcast-notification.dto';

@Injectable()
export class FcmService {
  private static readonly ELEVATED_ROLE_TARGETS = [
    RoleName.hunter,
    RoleName.dev,
    RoleName.admin,
    RoleName.owner,
  ] as const;

  private readonly logger = new Logger(FcmService.name);
  private readonly app?: App;
  private disabledReason: string | null = null;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    const projectId =
      this.configService.get<string>('FIREBASE_PROJECT_ID')?.trim() ?? '';
    const clientEmail =
      this.configService.get<string>('FIREBASE_CLIENT_EMAIL')?.trim() ?? '';
    const privateKeyRaw =
      this.configService.get<string>('FIREBASE_PRIVATE_KEY') ?? '';

    const missing: string[] = [];
    if (!projectId) missing.push('FIREBASE_PROJECT_ID');
    if (!clientEmail) missing.push('FIREBASE_CLIENT_EMAIL');
    if (!privateKeyRaw.trim()) missing.push('FIREBASE_PRIVATE_KEY');

    if (missing.length > 0) {
      this.disabledReason = `Missing ${missing.join(', ')}`;
      this.logger.warn(
        `FCM disabled: missing ${missing.join(', ')} in backend env.`,
      );
      return;
    }

    const privateKey = privateKeyRaw.replace(/\\n/g, '\n').trim();
    if (!privateKey.includes('BEGIN PRIVATE KEY')) {
      this.disabledReason = 'FIREBASE_PRIVATE_KEY format is invalid';
      this.logger.warn(
        'FCM disabled: FIREBASE_PRIVATE_KEY format looks invalid (missing BEGIN PRIVATE KEY).',
      );
      return;
    }

    if (getApps().length > 0) {
      const existing = getApps()[0];
      this.app = existing;
      const existingProjectId = (existing.options as { projectId?: string })
        .projectId;
      if (
        existingProjectId != null &&
        existingProjectId.trim().length > 0 &&
        existingProjectId !== projectId
      ) {
        this.logger.warn(
          `FCM using existing Firebase app projectId="${existingProjectId}", but FIREBASE_PROJECT_ID="${projectId}".`,
        );
      } else {
        this.logger.log(
          `FCM initialized with existing Firebase app (projectId="${existingProjectId ?? projectId}").`,
        );
      }
      return;
    }

    try {
      this.app = initializeApp({
        credential: cert({
          projectId,
          clientEmail,
          privateKey,
        }),
      });
      this.logger.log(`FCM initialized (projectId="${projectId}").`);
      this.disabledReason = null;
    } catch (error) {
      this.disabledReason =
        error instanceof Error ? error.message : String(error);
      this.logger.warn(
        `Invalid FCM credentials; push delivery disabled. ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }

  getStatus() {
    return {
      configured: this.app != null,
      reason:
        this.app == null
          ? (this.disabledReason ?? 'Firebase app is not initialized')
          : null,
    };
  }

  async sendToUsers(input: {
    userIds: string[];
    title: string;
    body: string;
    data?: Record<string, string | number | boolean | null | undefined>;
  }) {
    if (!this.app) {
      this.logger.warn(
        'FCM credentials are not configured; skipping targeted push send',
      );
      return {
        sentCount: 0,
        failureCount: 0,
        recipientCount: 0,
        skipped: true,
        skipReason: this.disabledReason ?? 'FCM not configured',
      };
    }

    const userIds = [...new Set(input.userIds.filter(Boolean))];
    if (userIds.length === 0) {
      return {
        sentCount: 0,
        failureCount: 0,
        recipientCount: 0,
        skipped: false,
      };
    }

    const tokens = await this.prisma.deviceToken.findMany({
      where: {
        userId: {
          in: userIds,
        },
      },
      select: { id: true, token: true },
    });

    if (tokens.length === 0) {
      return {
        sentCount: 0,
        failureCount: 0,
        recipientCount: userIds.length,
        skipped: false,
      };
    }

    const messaging = getMessaging(this.app);
    const batchSize = 500;
    let sentCount = 0;
    let failureCount = 0;
    const staleTokenIds: string[] = [];
    const data = this.toPushData(input.data);

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);
      const response = await messaging.sendEachForMulticast({
        tokens: batch.map((row) => row.token),
        notification: {
          title: input.title,
          body: input.body,
        },
        data,
      });

      sentCount += response.successCount;
      failureCount += response.failureCount;

      response.responses.forEach((result, index) => {
        const code = result.error?.code;
        if (
          code === 'messaging/invalid-registration-token' ||
          code === 'messaging/registration-token-not-registered'
        ) {
          staleTokenIds.push(batch[index].id);
        }
      });
    }

    if (staleTokenIds.length > 0) {
      await this.prisma.deviceToken.deleteMany({
        where: {
          id: {
            in: [...new Set(staleTokenIds)],
          },
        },
      });
    }

    return {
      sentCount,
      failureCount,
      recipientCount: userIds.length,
      skipped: false,
    };
  }

  async sendProjectUpdate(input: {
    projectId: string;
    updateId: string;
    actorName: string;
    title: string;
    body: string;
    urgency: string;
    userIds?: string[];
  }) {
    if (!this.app) {
      this.logger.warn(
        'FCM credentials are not configured; skipping push send',
      );
      return {
        sentCount: 0,
        failureCount: 0,
        recipientCount: 0,
        skipped: true,
        skipReason: this.disabledReason ?? 'FCM not configured',
      };
    }

    const userIds =
      input.userIds ??
      (
        await this.prisma.projectFollow.findMany({
          where: { projectId: input.projectId },
          select: { userId: true },
        })
      ).map((follow) => follow.userId);

    if (userIds.length === 0) {
      return {
        sentCount: 0,
        failureCount: 0,
        recipientCount: 0,
        skipped: false,
      };
    }

    return this.sendToUsers({
      userIds,
      title: input.title,
      body: input.body,
      data: {
        projectId: input.projectId,
        updateId: input.updateId,
        actorName: input.actorName,
        urgency: input.urgency,
        type: 'project_update',
      },
    });
  }

  async sendBroadcast(input: {
    title: string;
    body: string;
    target: BroadcastTarget;
    userIds?: string[];
    roles?: string[];
  }) {
    const resolvedUserIds = await this.resolveBroadcastUserIds(
      input.target,
      input.userIds,
    );
    return this.sendToUsers({
      userIds: resolvedUserIds,
      title: input.title,
      body: input.body,
      data: { type: 'broadcast', target: input.target },
    });
  }

  private async resolveBroadcastUserIds(
    target: BroadcastTarget,
    userIds?: string[],
  ) {
    if (target === 'specific' && userIds?.length) {
      return [...new Set(userIds)];
    }

    if (target === 'hunters') {
      const roles = await this.prisma.userRole.findMany({
        where: { role: { in: [...FcmService.ELEVATED_ROLE_TARGETS] } },
        select: { userId: true },
        distinct: ['userId'],
      });
      return roles.map((row) => row.userId);
    }

    if (target === 'users') {
      const elevated = await this.prisma.userRole.findMany({
        where: { role: { in: [...FcmService.ELEVATED_ROLE_TARGETS] } },
        select: { userId: true },
        distinct: ['userId'],
      });
      const elevatedIds = new Set(elevated.map((row) => row.userId));
      const all = await this.prisma.userRole.findMany({
        where: { role: RoleName.user },
        select: { userId: true },
        distinct: ['userId'],
      });
      return all.map((row) => row.userId).filter((id) => !elevatedIds.has(id));
    }

    const profiles = await this.prisma.profile.findMany({
      select: { id: true },
    });
    return profiles.map((profile) => profile.id);
  }

  private toPushData(
    data?: Record<string, string | number | boolean | null | undefined>,
  ): Record<string, string> {
    if (!data) {
      return {};
    }

    const mapped: Record<string, string> = {};
    Object.entries(data).forEach(([key, value]) => {
      if (value == null) return;
      mapped[key] = String(value);
    });
    return mapped;
  }
}
