import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { App, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import type { BroadcastTarget } from './dto/broadcast-notification.dto';

@Injectable()
export class FcmService {
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
      this.disabledReason = error instanceof Error
        ? error.message
        : String(error);
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
      reason: this.app == null
        ? this.disabledReason ?? 'Firebase app is not initialized'
        : null,
    };
  }

  async sendProjectUpdate(input: {
    projectId: string;
    updateId: string;
    actorName: string;
    title: string;
    body: string;
    urgency: string;
  }) {
    if (!this.app) {
      this.logger.warn(
        'FCM credentials are not configured; skipping push send',
      );
      return {
        sentCount: 0,
        skipped: true,
        skipReason: this.disabledReason ?? 'FCM not configured',
      };
    }

    const follows = await this.prisma.projectFollow.findMany({
      where: { projectId: input.projectId },
      select: { userId: true },
    });

    const userIds = follows.map((follow) => follow.userId);

    if (userIds.length === 0) {
      return { sentCount: 0, skipped: false };
    }

    const tokens = await this.prisma.deviceToken.findMany({
      where: {
        userId: {
          in: userIds,
        },
      },
      select: { token: true },
    });

    if (tokens.length === 0) {
      return { sentCount: 0, skipped: false };
    }

    const messaging = getMessaging(this.app);
    const response = await messaging.sendEachForMulticast({
      tokens: tokens.map((tokenRow) => tokenRow.token),
      notification: {
        title: input.title,
        body: input.body,
      },
      data: {
        projectId: input.projectId,
        updateId: input.updateId,
        actorName: input.actorName,
        urgency: input.urgency,
        type: 'project_update',
      },
    });

    return {
      sentCount: response.successCount,
      skipped: false,
      failureCount: response.failureCount,
    };
  }

  async sendBroadcast(input: {
    title: string;
    body: string;
    target: BroadcastTarget;
    userIds?: string[];
    roles?: string[];
  }) {
    if (!this.app) {
      this.logger.warn('FCM credentials are not configured; skipping broadcast');
      return {
        sentCount: 0,
        failureCount: 0,
        recipientCount: 0,
        skipped: true,
        skipReason: this.disabledReason ?? 'FCM not configured',
      };
    }

    // Resolve target user IDs
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
      // Users who only have the base 'user' role (no elevated roles)
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
      // 'all' — everyone with a device token
      const allTokens = await this.prisma.deviceToken.findMany({
        select: { userId: true },
        distinct: ['userId'],
      });
      resolvedUserIds = allTokens.map((t) => t.userId);
    }

    if (resolvedUserIds.length === 0) {
      return { sentCount: 0, skipped: false, recipientCount: 0 };
    }

    // Fetch FCM tokens in batches (FCM multicast max = 500)
    const tokens = await this.prisma.deviceToken.findMany({
      where: { userId: { in: resolvedUserIds } },
      select: { token: true },
    });

    if (tokens.length === 0) {
      return { sentCount: 0, skipped: false, recipientCount: resolvedUserIds.length };
    }

    const messaging = getMessaging(this.app);
    const tokenList = tokens.map((t) => t.token);
    const batchSize = 500;
    let totalSent = 0;
    let totalFailed = 0;

    for (let i = 0; i < tokenList.length; i += batchSize) {
      const batch = tokenList.slice(i, i + batchSize);
      const response = await messaging.sendEachForMulticast({
        tokens: batch,
        notification: { title: input.title, body: input.body },
        data: { type: 'broadcast' },
      });
      totalSent += response.successCount;
      totalFailed += response.failureCount;
    }

    return {
      sentCount: totalSent,
      failureCount: totalFailed,
      recipientCount: resolvedUserIds.length,
      skipped: false,
    };
  }
}
