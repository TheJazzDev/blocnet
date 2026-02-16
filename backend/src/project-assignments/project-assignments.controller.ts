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
import { AssignPosterDto } from './dto/assign-poster.dto';
import { InvitePosterDto } from './dto/invite-poster.dto';
import { ListInvitesQuery } from './dto/list-invites.query';
import { RespondInviteDto } from './dto/respond-invite.dto';
import { ProjectAssignmentsService } from './project-assignments.service';

@Controller()
@UseGuards(AuthGuard, RolesGuard)
export class ProjectAssignmentsController {
  constructor(
    private readonly projectAssignmentsService: ProjectAssignmentsService,
  ) {}

  @Post('projects/:projectId/posters/:posterId/assign')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async assignPoster(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId') projectId: string,
    @Param('posterId') posterId: string,
    @Body() dto: AssignPosterDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.projectAssignmentsService.assignPoster(
      user,
      projectId,
      posterId,
      dto.note,
    );
  }

  @Post('projects/:projectId/posters/:posterId/invite')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async invitePoster(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId') projectId: string,
    @Param('posterId') posterId: string,
    @Body() dto: InvitePosterDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.projectAssignmentsService.invitePoster(
      user,
      projectId,
      posterId,
      dto.note,
    );
  }

  @Get('projects/:projectId/invites')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async listProjectInvites(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId') projectId: string,
    @Query() query: ListInvitesQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.projectAssignmentsService.listProjectInvites(
      user,
      projectId,
      query.status,
      query.offset,
      query.limit,
    );
  }

  @Get('project-invites/mine')
  async listMyInvites(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListInvitesQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.projectAssignmentsService.listMyInvites(
      user,
      query.status,
      query.offset,
      query.limit,
    );
  }

  @Patch('project-invites/:inviteId/respond')
  async respondToInvite(
    @CurrentUser() user: AuthUser | undefined,
    @Param('inviteId') inviteId: string,
    @Body() dto: RespondInviteDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.projectAssignmentsService.respondToInvite(
      user,
      inviteId,
      dto.status,
    );
  }
}
