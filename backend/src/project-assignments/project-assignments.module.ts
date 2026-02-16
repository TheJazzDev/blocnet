import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { ProjectAssignmentsController } from './project-assignments.controller';
import { ProjectAssignmentsService } from './project-assignments.service';

@Module({
  imports: [AuditLogModule],
  controllers: [ProjectAssignmentsController],
  providers: [ProjectAssignmentsService],
  exports: [ProjectAssignmentsService],
})
export class ProjectAssignmentsModule {}
