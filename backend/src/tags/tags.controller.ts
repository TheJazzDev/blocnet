import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
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
  async createPrimaryTag(@Body() dto: CreatePrimaryTagDto) {
    return this.tagsService.createPrimaryTag(dto);
  }

  @Post('secondary')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async createSecondaryTag(@Body() dto: CreateSecondaryTagDto) {
    return this.tagsService.createSecondaryTag(dto);
  }

  @Patch('primary/:id')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updatePrimaryTag(
    @Param('id') id: string,
    @Body() dto: UpdatePrimaryTagDto,
  ) {
    return this.tagsService.updatePrimaryTag(id, dto);
  }

  @Patch('secondary/:id')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updateSecondaryTag(
    @Param('id') id: string,
    @Body() dto: UpdateSecondaryTagDto,
  ) {
    return this.tagsService.updateSecondaryTag(id, dto);
  }
}
