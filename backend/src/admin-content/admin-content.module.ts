import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { AdminContentController } from './admin-content.controller';
import { AdminCommunityService } from './services/admin-community.service';
import { AdminProjectsService } from './services/admin-projects.service';
import { AdminUpdatesService } from './services/admin-updates.service';

@Module({
  imports: [AuditLogModule],
  controllers: [AdminContentController],
  providers: [AdminProjectsService, AdminUpdatesService, AdminCommunityService],
  exports: [AdminProjectsService, AdminUpdatesService, AdminCommunityService],
})
export class AdminContentModule {}
