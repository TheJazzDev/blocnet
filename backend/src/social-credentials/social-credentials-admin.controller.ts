import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
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
import { CreateSocialCredentialDto } from './dto/create-social-credential.dto';
import { UpdateSocialCredentialDto } from './dto/update-social-credential.dto';
import { SocialCredentialsService } from './social-credentials.service';

@Controller('admin/settings/social-credentials')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.OWNER)
export class SocialCredentialsAdminController {
  constructor(
    private readonly socialCredentialsService: SocialCredentialsService,
    private readonly auditLogService: AuditLogService,
  ) {}

  @Get()
  async list(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const data = await this.socialCredentialsService.list();
    await this.auditLogService.create({
      actorId: user.id,
      action: 'settings.social_credentials.list',
      resourceType: 'social_credential',
      metadata: { count: data.length },
    });
    return { data };
  }

  @Get(':id/reveal')
  async reveal(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id', new ParseUUIDPipe()) id: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const revealed = await this.socialCredentialsService.revealPassword(id);
    await this.auditLogService.create({
      actorId: user.id,
      action: 'settings.social_credentials.reveal',
      resourceType: 'social_credential',
      resourceId: id,
    });
    return revealed;
  }

  @Post()
  async create(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreateSocialCredentialDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const created = await this.socialCredentialsService.create(user.id, dto);
    await this.auditLogService.create({
      actorId: user.id,
      action: 'settings.social_credentials.create',
      resourceType: 'social_credential',
      resourceId: created.id,
      metadata: {
        provider: created.provider,
        username: created.username,
        accountLabel: created.accountLabel,
      },
    });
    return created;
  }

  @Patch(':id')
  async update(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body() dto: UpdateSocialCredentialDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const updated = await this.socialCredentialsService.update(
      id,
      user.id,
      dto,
    );
    await this.auditLogService.create({
      actorId: user.id,
      action: 'settings.social_credentials.update',
      resourceType: 'social_credential',
      resourceId: updated.id,
      metadata: {
        provider: updated.provider,
        username: updated.username,
        accountLabel: updated.accountLabel,
        passwordUpdated: dto.password !== undefined,
      },
    });
    return updated;
  }

  @Delete(':id')
  async remove(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id', new ParseUUIDPipe()) id: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const deleted = await this.socialCredentialsService.remove(id);
    await this.auditLogService.create({
      actorId: user.id,
      action: 'settings.social_credentials.delete',
      resourceType: 'social_credential',
      resourceId: id,
    });
    return deleted;
  }
}
