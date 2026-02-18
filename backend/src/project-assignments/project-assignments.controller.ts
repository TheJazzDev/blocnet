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
import { AssignHunterDto } from './dto/assign-hunter.dto';
import { InviteHunterDto } from './dto/invite-hunter.dto';
import { ListInvitesQuery } from './dto/list-invites.query';
import { RespondInviteDto } from './dto/respond-invite.dto';
import { ProjectAssignmentsService } from './project-assignments.service';

@Controller()
@UseGuards(AuthGuard, RolesGuard)
export class ProjectAssignmentsController {
  constructor(
    private readonly projectAssignmentsService: ProjectAssignmentsService,
  ) {}

  @Post('projects/:projectId/hunters/:hunterId/assign')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async assignHunter(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId') projectId: string,
    @Param('hunterId') hunterId: string,
    @Body() dto: AssignHunterDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.projectAssignmentsService.assignHunter(
      user,
      projectId,
      hunterId,
      dto.note,
    );
  }

  @Post('projects/:projectId/hunters/:hunterId/invite')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async inviteHunter(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId') projectId: string,
    @Param('hunterId') hunterId: string,
    @Body() dto: InviteHunterDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.projectAssignmentsService.inviteHunter(
      user,
      projectId,
      hunterId,
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
