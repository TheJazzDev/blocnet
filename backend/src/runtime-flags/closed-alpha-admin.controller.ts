import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
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
import { ClosedAlphaAccessService } from './closed-alpha-access.service';
import { CreateClosedAlphaEmailDto } from './dto/create-closed-alpha-email.dto';
import { ListClosedAlphaEmailsQuery } from './dto/list-closed-alpha-emails.query';
import { UpdateClosedAlphaEmailDto } from './dto/update-closed-alpha-email.dto';

@Controller('admin/settings/closed-alpha/emails')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.OWNER, AppRole.DEV, AppRole.ADMIN)
export class ClosedAlphaAdminController {
  constructor(
    private readonly closedAlphaAccessService: ClosedAlphaAccessService,
    private readonly auditLogService: AuditLogService,
  ) {}

  @Get()
  async list(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListClosedAlphaEmailsQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const result = await this.closedAlphaAccessService.listEmails({
      q: query.q,
      limit: query.limit,
      offset: query.offset,
    });

    await this.auditLogService.create({
      actorId: user.id,
      action: 'settings.closed_alpha.allowlist.view',
      resourceType: 'closed_alpha_allowlist',
      resourceId: 'default',
      metadata: {
        q: query.q ?? null,
        limit: result.limit,
        offset: result.offset,
        total: result.total,
      },
    });

    return result;
  }

  @Post()
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async create(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreateClosedAlphaEmailDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const row = await this.closedAlphaAccessService.addAdminEmail({
      email: dto.email,
      note: dto.note,
      isActive: dto.isActive,
      createdById: user.id,
    });

    await this.auditLogService.create({
      actorId: user.id,
      action: 'settings.closed_alpha.allowlist.add',
      resourceType: 'closed_alpha_email',
      resourceId: row.id,
      metadata: {
        email: row.email,
        isActive: row.isActive,
        source: row.source,
      },
    });

    return row;
  }

  @Patch(':id')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updateStatus(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: UpdateClosedAlphaEmailDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const row = await this.closedAlphaAccessService.setActive(id, dto.isActive);
    await this.auditLogService.create({
      actorId: user.id,
      action: 'settings.closed_alpha.allowlist.status',
      resourceType: 'closed_alpha_email',
      resourceId: row.id,
      metadata: {
        email: row.email,
        isActive: row.isActive,
      },
    });

    return row;
  }

  @Delete(':id')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async remove(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const row = await this.closedAlphaAccessService.remove(id);
    await this.auditLogService.create({
      actorId: user.id,
      action: 'settings.closed_alpha.allowlist.remove',
      resourceType: 'closed_alpha_email',
      resourceId: row.id,
      metadata: {
        email: row.email,
      },
    });

    return { id: row.id, deleted: true };
  }
}
