import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { BadgesModule } from '../badges/badges.module';
import { BlocksModule } from '../blocks/blocks.module';
import { LevelsModule } from '../levels/levels.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { QuestsModule } from '../quests/quests.module';
import { UpdateReactionsController } from './update-reactions.controller';
import { UpdateReactionsService } from './update-reactions.service';
import { UpdatesController } from './updates.controller';
import { UpdatesService } from './updates.service';

@Module({
  imports: [
    NotificationsModule,
    AuditLogModule,
    BadgesModule,
    BlocksModule,
    LevelsModule,
    QuestsModule,
  ],
  controllers: [UpdatesController, UpdateReactionsController],
  providers: [UpdatesService, UpdateReactionsService],
  exports: [UpdatesService],
})
export class UpdatesModule {}
