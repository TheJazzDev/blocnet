import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { RolesModule } from '../roles/roles.module';
import { AdminApplicationsController } from './admin-applications.controller';
import { AdminApplicationsService } from './admin-applications.service';

@Module({
  imports: [RolesModule, AuditLogModule],
  controllers: [AdminApplicationsController],
  providers: [AdminApplicationsService],
  exports: [AdminApplicationsService],
})
export class AdminApplicationsModule {}
