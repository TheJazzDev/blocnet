import {
  Body,
  Controller,
  Get,
  Patch,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { AuditLogService } from '../audit-log/audit-log.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { UpdateRuntimeFeatureFlagsDto } from './dto/update-runtime-feature-flags.dto';
import { RuntimeFeatureFlagsService } from './runtime-feature-flags.service';

@Controller('admin/settings/runtime-features')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR)
export class RuntimeFeatureFlagsAdminController {
  constructor(
    private readonly runtimeFeatureFlagsService: RuntimeFeatureFlagsService,
    private readonly auditLogService: AuditLogService,
  ) {}

  @Get()
  async getConfig(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const config = await this.runtimeFeatureFlagsService.getConfig();
    await this.auditLogService.create({
      actorId: user.id,
      action: 'settings.runtime_features.view',
      resourceType: 'runtime_feature_config',
      resourceId: config.id,
    });
    return config;
  }

  @Patch()
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updateConfig(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: UpdateRuntimeFeatureFlagsDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const config = await this.runtimeFeatureFlagsService.updateConfig(dto);
    await this.auditLogService.create({
      actorId: user.id,
      action: 'settings.runtime_features.update',
      resourceType: 'runtime_feature_config',
      resourceId: config.id,
      metadata: config,
    });
    return config;
  }
}
