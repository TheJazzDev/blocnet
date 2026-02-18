import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
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
import { CreateUpdateDto } from './dto/create-update.dto';
import { ListUpdatesQuery } from './dto/list-updates.query';
import { UpdateUpdateDto } from './dto/update-update.dto';
import { UpdatesService } from './updates.service';

@Controller()
export class UpdatesController {
  constructor(private readonly updatesService: UpdatesService) {}

  @Post('projects/:projectId/updates')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.HUNTER)
  async createUpdate(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId') projectId: string,
    @Body() dto: CreateUpdateDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.updatesService.createUpdate(user, projectId, dto);
  }

  @Get('updates')
  async listUpdates(@Query() query: ListUpdatesQuery) {
    return this.updatesService.listUpdates(query);
  }

  @Get('updates/:id')
  async getUpdate(@Param('id') id: string) {
    return this.updatesService.getUpdate(id);
  }

  @Patch('updates/:id')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.HUNTER)
  async updateUpdate(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: UpdateUpdateDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.updatesService.updateUpdate(user, id, dto);
  }
}
