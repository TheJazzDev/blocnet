import {
  Body,
  Controller,
  Param,
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
import { AssignPosterDto } from './dto/assign-poster.dto';
import { ProjectAssignmentsService } from './project-assignments.service';

@Controller('projects/:projectId/posters/:posterId')
@UseGuards(AuthGuard, RolesGuard)
export class ProjectAssignmentsController {
  constructor(
    private readonly projectAssignmentsService: ProjectAssignmentsService,
  ) {}

  @Post('assign')
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
}
