import {
  Body,
  Controller,
  Get,
  Param,
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
import { ListAdminCommentsQuery } from './dto/list-admin-comments.query';
import { ListAdminCommunityCommentsQuery } from './dto/list-admin-community-comments.query';
import { ListAdminCommunityPostsQuery } from './dto/list-admin-community-posts.query';
import { ListAdminProjectsQuery } from './dto/list-admin-projects.query';
import { ListAdminUpdatesQuery } from './dto/list-admin-updates.query';
import { ModerateCommentStatusDto } from './dto/moderate-comment-status.dto';
import { ModerateCommunityCommentStatusDto } from './dto/moderate-community-comment-status.dto';
import { ModerateCommunityPostStatusDto } from './dto/moderate-community-post-status.dto';
import { ModerateProjectStatusDto } from './dto/moderate-project-status.dto';
import { ModerateUpdateStatusDto } from './dto/moderate-update-status.dto';
import { AdminCommunityService } from './services/admin-community.service';
import { AdminProjectsService } from './services/admin-projects.service';
import { AdminUpdatesService } from './services/admin-updates.service';

@Controller('admin/content')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR)
export class AdminContentController {
  constructor(
    private readonly adminProjectsService: AdminProjectsService,
    private readonly adminUpdatesService: AdminUpdatesService,
    private readonly adminCommunityService: AdminCommunityService,
  ) {}

  @Get('projects')
  async listProjects(@Query() query: ListAdminProjectsQuery) {
    return this.adminProjectsService.listProjects(query);
  }

  @Patch('projects/:id/status')
  async moderateProjectStatus(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: ModerateProjectStatusDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.adminProjectsService.moderateProjectStatus(user, id, dto);
  }

  @Get('updates')
  async listUpdates(@Query() query: ListAdminUpdatesQuery) {
    return this.adminUpdatesService.listUpdates(query);
  }

  @Patch('updates/:id/status')
  async moderateUpdateStatus(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: ModerateUpdateStatusDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.adminUpdatesService.moderateUpdateStatus(user, id, dto);
  }

  @Get('comments')
  async listComments(@Query() query: ListAdminCommentsQuery) {
    return this.adminUpdatesService.listComments(query);
  }

  @Patch('comments/:id/status')
  async moderateCommentStatus(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: ModerateCommentStatusDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.adminUpdatesService.moderateCommentStatus(user, id, dto);
  }

  @Get('community-posts')
  async listCommunityPosts(@Query() query: ListAdminCommunityPostsQuery) {
    return this.adminCommunityService.listCommunityPosts(query);
  }

  @Patch('community-posts/:id/status')
  async moderateCommunityPostStatus(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: ModerateCommunityPostStatusDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.adminCommunityService.moderateCommunityPostStatus(user, id, dto);
  }

  @Get('community-comments')
  async listCommunityComments(@Query() query: ListAdminCommunityCommentsQuery) {
    return this.adminCommunityService.listCommunityComments(query);
  }

  @Patch('community-comments/:id/status')
  async moderateCommunityCommentStatus(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: ModerateCommunityCommentStatusDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.adminCommunityService.moderateCommunityCommentStatus(
      user,
      id,
      dto,
    );
  }
}
