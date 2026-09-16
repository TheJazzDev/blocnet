import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { LevelsModule } from '../levels/levels.module';
import { ProjectAssignmentsController } from './project-assignments.controller';
import { ProjectAssignmentsService } from './project-assignments.service';
import { ProjectHandoverController } from './project-handover.controller';
import { ProjectHandoverService } from './project-handover.service';

@Module({
  imports: [AuditLogModule, LevelsModule],
  controllers: [ProjectAssignmentsController, ProjectHandoverController],
  providers: [ProjectAssignmentsService, ProjectHandoverService],
  exports: [ProjectAssignmentsService],
})
export class ProjectAssignmentsModule {}
