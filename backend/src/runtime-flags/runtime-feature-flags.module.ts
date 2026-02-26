import { Global, Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { RuntimeFeatureFlagsAdminController } from './runtime-feature-flags-admin.controller';
import { RuntimeFeatureFlagsService } from './runtime-feature-flags.service';

@Global()
@Module({
  imports: [AuditLogModule],
  controllers: [RuntimeFeatureFlagsAdminController],
  providers: [RuntimeFeatureFlagsService],
  exports: [RuntimeFeatureFlagsService],
})
export class RuntimeFeatureFlagsModule {}
