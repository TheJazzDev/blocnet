import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { MiningAdminController } from './mining-admin.controller';
import { MiningController } from './mining.controller';
import { MiningService } from './mining.service';

@Module({
  imports: [AuditLogModule],
  controllers: [MiningController, MiningAdminController],
  providers: [MiningService],
  exports: [MiningService],
})
export class MiningModule {}
