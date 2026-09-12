import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ProjectAttentionController } from './project-attention.controller';
import { ProjectAttentionService } from './project-attention.service';

@Module({
  imports: [PrismaModule, NotificationsModule, AuditLogModule],
  controllers: [ProjectAttentionController],
  providers: [ProjectAttentionService],
  exports: [ProjectAttentionService],
})
export class ProjectAttentionModule {}
