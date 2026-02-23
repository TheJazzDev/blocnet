import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuditLogService } from './audit-log.service';

@Controller('audit-log')
@UseGuards(AuthGuard, RolesGuard)
export class AuditLogController {
  constructor(private readonly auditLogService: AuditLogService) {}

  @Get()
  @Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR)
  async list(@Query('limit') limit?: string, @Query('offset') offset?: string) {
    const parsedLimit = limit ? Number(limit) : 100;
    const parsedOffset = offset ? Number(offset) : 0;
    return this.auditLogService.list(parsedLimit, parsedOffset);
  }
}
