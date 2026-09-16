import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { HunterReliabilityModule } from '../hunter-reliability/hunter-reliability.module';
import { LevelsModule } from '../levels/levels.module';
import { ProjectsController } from './projects.controller';
import { ProjectsService } from './projects.service';

@Module({
  imports: [AuditLogModule, LevelsModule, HunterReliabilityModule],
  controllers: [ProjectsController],
  providers: [ProjectsService],
  exports: [ProjectsService],
})
export class ProjectsModule {}
