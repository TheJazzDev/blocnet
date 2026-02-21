import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { MeRadarController } from './me-radar.controller';
import { MeRadarService } from './me-radar.service';

@Module({
  imports: [AuditLogModule],
  controllers: [MeRadarController],
  providers: [MeRadarService],
  exports: [MeRadarService],
})
export class MeRadarModule {}
