import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { CreatePrimaryTagDto } from './dto/create-primary-tag.dto';
import { CreateSecondaryTagDto } from './dto/create-secondary-tag.dto';
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
}
