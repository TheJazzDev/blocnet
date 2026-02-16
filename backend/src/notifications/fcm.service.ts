import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { App, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

@Injectable()
export class FcmService {
  private readonly logger = new Logger(FcmService.name);
  private readonly app?: App;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = this.configService.get<string>('FIREBASE_CLIENT_EMAIL');
    const privateKeyRaw = this.configService.get<string>('FIREBASE_PRIVATE_KEY');

    if (!projectId || !clientEmail || !privateKeyRaw) {
      return;
    }

    const privateKey = privateKeyRaw.replace(/\\n/g, '\n');

    if (getApps().length > 0) {
      this.app = getApps()[0];
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
    } catch (error) {
      this.logger.warn(
        `Invalid FCM credentials; push delivery disabled. ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }

  async sendProjectPostUpdate(input: {
    projectId: string;
    postId: string;
    title: string;
    body: string;
    urgency: string;
  }) {
    if (!this.app) {
      this.logger.warn('FCM credentials are not configured; skipping push send');
      return { sentCount: 0, skipped: true };
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
        postId: input.postId,
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
}
