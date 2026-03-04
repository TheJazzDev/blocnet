import { Module } from '@nestjs/common';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { LevelsController } from './levels.controller';
import { LevelsService } from './levels.service';
import { LevelEventsService } from './level-events.service';
import { LevelNotificationsListener } from './level-notifications.listener';
import { LevelIconStorageService } from './level-icon-storage.service';
import { PrismaModule } from '../prisma/prisma.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [PrismaModule, NotificationsModule, EventEmitterModule.forRoot()],
  controllers: [LevelsController],
  providers: [
    LevelsService,
    LevelEventsService,
    LevelNotificationsListener,
    LevelIconStorageService,
  ],
  exports: [LevelsService, LevelEventsService],
})
export class LevelsModule {}
