import { Global, Module } from '@nestjs/common';
import { AdminTwoFactorModule } from '../admin-security/admin-two-factor.module';
import { AuthModule } from '../auth/auth.module';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { RuntimeFeatureFlagsAdminController } from './runtime-feature-flags-admin.controller';
import { RuntimeFeatureFlagsService } from './runtime-feature-flags.service';

@Global()
@Module({
  imports: [AuditLogModule, AuthModule, AdminTwoFactorModule],
  controllers: [RuntimeFeatureFlagsAdminController],
  providers: [RuntimeFeatureFlagsService, AuthGuard, RolesGuard],
  exports: [RuntimeFeatureFlagsService],
})
export class RuntimeFeatureFlagsModule {}
