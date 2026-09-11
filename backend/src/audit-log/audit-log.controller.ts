import {
  Controller,
  Get,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import {
  Roles,
  RolesDeniedMessage,
} from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { ApiOperation, ApiResponse } from '@nestjs/swagger';
import { ListAuditLogQuery } from './dto/list-audit-log.query';
import { ListOpsEventsQuery } from './dto/list-ops-events.query';
import { AuditLogService } from './audit-log.service';

@Controller('audit-log')
@UseGuards(AuthGuard, RolesGuard)
export class AuditLogController {
  constructor(private readonly auditLogService: AuditLogService) {}

  @Get()
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  @ApiOperation({
    summary: 'List audit log entries visible to the caller',
    description:
      'Pass includeViews=false to exclude read-only admin view events (actions ending in ".view").',
  })
  async list(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListAuditLogQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.auditLogService.listForUser(
      user,
      query.limit ?? 100,
      query.offset ?? 0,
      { includeViews: query.includeViews ?? true },
    );
  }

  @Get('ops-events')
  @Roles(AppRole.OWNER, AppRole.DEV)
  @RolesDeniedMessage('Only owner or dev can view ops events')
  @ApiOperation({ summary: 'List ops events (owner/dev only)' })
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
  @RolesDeniedMessage('Only owner or dev can view system alerts')
  @ApiOperation({
    summary: 'List system alerts (owner/dev only)',
    description:
      'Warning/error ops events. Admins are refused with a 403 whose message is safe to display.',
  })
  @ApiResponse({
    status: 403,
    description: 'Only owner or dev can view system alerts',
  })
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
