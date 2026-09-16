import {
  Body,
  Controller,
  Delete,
  Param,
  ParseUUIDPipe,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { StartHandoverDto } from './dto/start-handover.dto';
import { ProjectHandoverService } from './project-handover.service';

/**
 * No role gate: the right to hand a gem over is owning it, which the service
 * checks against `ownersOf`.
 */
@ApiTags('project-assignments')
@ApiBearerAuth()
@Controller('projects/:projectId/handover')
@UseGuards(AuthGuard)
export class ProjectHandoverController {
  constructor(private readonly handover: ProjectHandoverService) {}

  @Post()
  @ApiOperation({
    summary:
      'Offer your gem to another hunter. They answer through PATCH /project-invites/:id/respond; accepting makes the gem theirs.',
  })
  @ApiBadRequestResponse({ description: 'Yourself, or a deactivated account.' })
  @ApiForbiddenResponse({
    description: 'You do not own the gem, or the target is not a hunter.',
  })
  @ApiNotFoundResponse({ description: 'No such gem or hunter.' })
  @ApiConflictResponse({
    description:
      'The gem already has a pending handover, or the hunter already has a pending invite to it.',
  })
  async start(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId', ParseUUIDPipe) projectId: string,
    @Body() dto: StartHandoverDto,
  ) {
    if (!user) throw new UnauthorizedException('User context missing');
    return this.handover.startHandover(user, projectId, dto.hunter, dto.note);
  }

  @Delete()
  @ApiOperation({ summary: 'Withdraw the handover you have pending on a gem.' })
  @ApiNotFoundResponse({ description: 'You have no pending handover on it.' })
  async cancel(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId', ParseUUIDPipe) projectId: string,
  ) {
    if (!user) throw new UnauthorizedException('User context missing');
    return this.handover.cancelHandover(user, projectId);
  }
}
