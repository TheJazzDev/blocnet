import { Global, Module } from '@nestjs/common';
import { AdminTwoFactorModule } from '../admin-security/admin-two-factor.module';
import { AuthModule } from '../auth/auth.module';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { ClosedAlphaAdminController } from './closed-alpha-admin.controller';
import { ClosedAlphaPublicController } from './closed-alpha-public.controller';
import { ClosedAlphaAccessService } from './closed-alpha-access.service';
import { RuntimeFeatureFlagsAdminController } from './runtime-feature-flags-admin.controller';
import { RuntimeFeatureFlagsService } from './runtime-feature-flags.service';

@Global()
@Module({
  imports: [AuditLogModule, AuthModule, AdminTwoFactorModule],
  controllers: [
    RuntimeFeatureFlagsAdminController,
    ClosedAlphaAdminController,
    ClosedAlphaPublicController,
  ],
  providers: [
    RuntimeFeatureFlagsService,
    ClosedAlphaAccessService,
    AuthGuard,
    RolesGuard,
  ],
  exports: [RuntimeFeatureFlagsService, ClosedAlphaAccessService],
})
export class RuntimeFeatureFlagsModule {}
