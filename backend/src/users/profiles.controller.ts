import {
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Post,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { SearchPublicProfilesQuery } from './dto/search-public-profiles.query';
import { UsersService } from './users.service';

@Controller('profiles')
export class ProfilesController {
  constructor(private readonly usersService: UsersService) {}

  @Get('search')
  @UseGuards(AuthGuard)
  async searchProfiles(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: SearchPublicProfilesQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.searchPublicProfiles({
      q: query.q,
      role: query.role,
      limit: query.limit,
      offset: query.offset,
    });
  }

  @Get(':id/public')
  async getPublicProfile(@Param('id') id: string) {
    const profile = await this.usersService.getPublicProfile(id);

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    return profile;
  }

  @Post(':id/follow')
  @UseGuards(AuthGuard)
  async followProfile(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.followProfile(user.id, id);
  }

  @Delete(':id/follow')
  @UseGuards(AuthGuard)
  async unfollowProfile(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.unfollowProfile(user.id, id);
  }
}
