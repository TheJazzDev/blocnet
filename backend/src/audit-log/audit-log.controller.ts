import {
  Controller,
  Get,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { ListOpsEventsQuery } from './dto/list-ops-events.query';
import { AuditLogService } from './audit-log.service';

@Controller('audit-log')
@UseGuards(AuthGuard, RolesGuard)
export class AuditLogController {
  constructor(private readonly auditLogService: AuditLogService) {}

  @Get()
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async list(
    @CurrentUser() user: AuthUser | undefined,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const parsedLimit = limit ? Number(limit) : 100;
    const parsedOffset = offset ? Number(offset) : 0;
    return this.auditLogService.listForUser(user, parsedLimit, parsedOffset);
  }

  @Get('ops-events')
  @Roles(AppRole.OWNER, AppRole.DEV)
  async listOpsEvents(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListOpsEventsQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.auditLogService.listOpsEvents(user, query);
  }

  @Get('system-alerts')
  @Roles(AppRole.OWNER, AppRole.DEV)
  async listSystemAlerts(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListOpsEventsQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.auditLogService.listSystemAlerts(user, query);
  }
}
