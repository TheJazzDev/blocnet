import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { EdgeEngineAdminController } from './edge-engine-admin.controller';
import { EdgeEngineController } from './edge-engine.controller';
import { EdgeEngineService } from './edge-engine.service';
import { EdgeAdminService } from './edge-admin.service';

@Module({
  imports: [AuditLogModule],
  controllers: [EdgeEngineController, EdgeEngineAdminController],
  providers: [EdgeEngineService, EdgeAdminService],
  exports: [EdgeEngineService, EdgeAdminService],
})
export class EdgeEngineModule {}
