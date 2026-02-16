import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { ProjectsModule } from '../projects/projects.module';
import { ProjectProposalsController } from './project-proposals.controller';
import { ProjectProposalsService } from './project-proposals.service';

@Module({
  imports: [ProjectsModule, AuditLogModule],
  controllers: [ProjectProposalsController],
  providers: [ProjectProposalsService],
  exports: [ProjectProposalsService],
})
export class ProjectProposalsModule {}
