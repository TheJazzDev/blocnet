import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { TipsAdminController } from './tips-admin.controller';
import { TipsController } from './tips.controller';
import { TipsService } from './tips.service';

@Module({
  imports: [AuditLogModule, NotificationsModule],
  controllers: [TipsController, TipsAdminController],
  providers: [TipsService],
  exports: [TipsService],
})
export class TipsModule {}
