import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { UpdateFollowPreferencesDto } from './dto/update-follow-preferences.dto';
import { FollowsService } from './follows.service';

@Controller('projects/:projectId/follow')
@UseGuards(AuthGuard)
export class FollowsController {
  constructor(private readonly followsService: FollowsService) {}

  @Post()
  async follow(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId') projectId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.followsService.followProject(user.id, projectId);
  }

  @Delete()
  async unfollow(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId') projectId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.followsService.unfollowProject(user.id, projectId);
  }

  @Get('preferences')
  async getPreferences(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId') projectId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.followsService.getFollowPreferences(user.id, projectId);
  }

  @Patch('preferences')
  async updatePreferences(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId') projectId: string,
    @Body() dto: UpdateFollowPreferencesDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.followsService.updateFollowPreferences(user.id, projectId, dto);
  }
}
