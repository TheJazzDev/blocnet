import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { ProjectAttentionService } from './project-attention.service';

/// Members acting when a hunter stops keeping a gem current.
@ApiTags('projects')
@Controller('projects/:projectId')
@UseGuards(AuthGuard)
export class ProjectAttentionController {
  constructor(private readonly attention: ProjectAttentionService) {}

  @Post('request-update')
  @ApiOperation({
    summary:
      'Ask this gem’s hunter for an update. Followers only, once per week; the hunter is notified once per gem per week however many members ask.',
  })
  async requestUpdate(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId', ParseUUIDPipe) projectId: string,
  ) {
    if (!user) throw new UnauthorizedException('User context missing');
    return this.attention.requestUpdate(user.id, projectId);
  }

  @Post('report-inactive')
  @ApiOperation({
    summary:
      'Report that this gem has been abandoned. Raises it to moderators; it does not reassign the gem.',
  })
  async reportInactive(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId', ParseUUIDPipe) projectId: string,
  ) {
    if (!user) throw new UnauthorizedException('User context missing');
    return this.attention.reportInactive(user.id, projectId);
  }

  @Get('attention')
  @ApiOperation({
    summary:
      'How many members are waiting on this gem, and how many open inactivity reports it has.',
  })
  async attention_(
    @Param('projectId', ParseUUIDPipe) projectId: string,
  ) {
    return this.attention.attentionFor(projectId);
  }
}
