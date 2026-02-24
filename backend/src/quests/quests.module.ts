import { Module } from '@nestjs/common';
import { BadgesModule } from '../badges/badges.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { QuestsAdminController } from './quests-admin.controller';
import { QuestsController } from './quests.controller';
import { QuestsService } from './quests.service';

@Module({
  imports: [PrismaModule, BadgesModule, NotificationsModule],
  controllers: [QuestsController, QuestsAdminController],
  providers: [QuestsService],
  exports: [QuestsService],
})
export class QuestsModule {}
