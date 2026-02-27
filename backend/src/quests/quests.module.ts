import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { BadgesModule } from '../badges/badges.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { QuestsAdminController } from './quests-admin.controller';
import { QuestsController } from './quests.controller';
import { QuestsService } from './quests.service';
import { QuestStorageService } from './quest-storage.service';

@Module({
  imports: [PrismaModule, BadgesModule, NotificationsModule, AuditLogModule],
  controllers: [QuestsController, QuestsAdminController],
  providers: [QuestsService, QuestStorageService],
  exports: [QuestsService, QuestStorageService],
})
export class QuestsModule {}
