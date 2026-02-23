import {
  Body,
  Controller,
  Get,
  Patch,
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
import { GetAdminEdgeOverviewQuery } from './dto/get-admin-edge-overview.query';
import { UpdateEdgeConfigDto } from './dto/update-edge-config.dto';
import { EdgeEngineService } from './edge-engine.service';

@Controller('admin/edge')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR)
export class EdgeEngineAdminController {
  constructor(private readonly edgeEngineService: EdgeEngineService) {}

  @Get('config')
  async getConfig(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.edgeEngineService.getAdminConfig(user.id);
  }

  @Patch('config')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updateConfig(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: UpdateEdgeConfigDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.edgeEngineService.updateAdminConfig(user.id, dto);
  }

  @Get('overview')
  async getOverview(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: GetAdminEdgeOverviewQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.edgeEngineService.getAdminOverview(user.id, query);
  }
}
