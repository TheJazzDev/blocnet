import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { MentionsService } from './mentions.service';
import { MentionsController } from './mentions.controller';

@Module({
  imports: [PrismaModule, NotificationsModule],
  controllers: [MentionsController],
  providers: [MentionsService],
  exports: [MentionsService],
})
export class MentionsModule {}
