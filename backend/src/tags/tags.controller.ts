import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { CreatePrimaryTagDto } from './dto/create-primary-tag.dto';
import { CreateSecondaryTagDto } from './dto/create-secondary-tag.dto';
import { UpdatePrimaryTagDto } from './dto/update-primary-tag.dto';
import { UpdateSecondaryTagDto } from './dto/update-secondary-tag.dto';
import { TagsService } from './tags.service';

@Controller('tags')
export class TagsController {
  constructor(private readonly tagsService: TagsService) {}

  @Get('primary')
  async listPrimaryTags() {
    return this.tagsService.listPrimaryTags();
  }

  @Get('secondary')
  async listSecondaryTags() {
    return this.tagsService.listSecondaryTags();
  }

  @Post('primary')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async createPrimaryTag(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreatePrimaryTagDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.tagsService.createPrimaryTag(user.id, dto);
  }

  @Post('secondary')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async createSecondaryTag(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreateSecondaryTagDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.tagsService.createSecondaryTag(user.id, dto);
  }

  @Patch('primary/:id')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updatePrimaryTag(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: UpdatePrimaryTagDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.tagsService.updatePrimaryTag(user.id, id, dto);
  }

  @Patch('secondary/:id')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updateSecondaryTag(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: UpdateSecondaryTagDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.tagsService.updateSecondaryTag(user.id, id, dto);
  }
}
