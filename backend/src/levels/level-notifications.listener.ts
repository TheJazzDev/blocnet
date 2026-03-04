import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import type { LevelUpEvent } from './level-events.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '@prisma/client';

@Injectable()
export class LevelNotificationsListener {
  private readonly logger = new Logger(LevelNotificationsListener.name);

  constructor(private notificationsService: NotificationsService) {}

  @OnEvent('level.up')
  async handleLevelUp(event: LevelUpEvent) {
    try {
      const levelName = event.newLevel.name;
      const levelNumber = event.newLevel.level;

      await this.notificationsService.notifyMany(
        [
          {
            userId: event.userId,
            type: NotificationType.level_up,
            title: `🎉 Congratulations! You're now ${levelName}!`,
            body: `You've reached Level ${levelNumber}. Keep up the great work in the Blocnet community!`,
            deeplink: `/profile`,
            payload: {
              levelId: event.newLevel.id,
              levelNumber,
              levelName,
              previousLevel: event.previousLevel?.level || 0,
            },
          },
        ],
        { push: true },
      );

      this.logger.log(
        `Level-up notification sent to user ${event.userId}: Level ${levelNumber}`,
      );
    } catch (error) {
      this.logger.error(
        `Failed to send level-up notification for user ${event.userId}`,
        error instanceof Error ? error.stack : String(error),
      );
    }
  }
}
