import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { BadgesAdminController } from './badges-admin.controller';
import { BadgesController } from './badges.controller';
import { BadgesService } from './badges.service';

@Module({
  imports: [PrismaModule, NotificationsModule, AuditLogModule],
  controllers: [BadgesController, BadgesAdminController],
  providers: [BadgesService],
  exports: [BadgesService],
})
export class BadgesModule {}
