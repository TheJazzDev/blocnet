import {
  Body,
  Controller,
  Get,
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
import { UpdateMeDto } from './dto/update-me.dto';
import { UsersService } from './users.service';

@Controller('me')
@UseGuards(AuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  async getMe(@CurrentUser() user?: AuthUser) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.getMe(user.id);
  }

  @Get('watchlist')
  async getWatchlist(
    @CurrentUser() user: AuthUser | undefined,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.listWatchlist(user.id, {
      limit: limit ? Number(limit) : undefined,
      offset: offset ? Number(offset) : undefined,
    });
  }

  @Get('bookmarks')
  async getBookmarks(
    @CurrentUser() user: AuthUser | undefined,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.listBookmarks(user.id, {
      limit: limit ? Number(limit) : undefined,
      offset: offset ? Number(offset) : undefined,
    });
  }

  @Get('activity')
  async getActivity(
    @CurrentUser() user: AuthUser | undefined,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.listMyActivity(user.id, {
      limit: limit ? Number(limit) : undefined,
      offset: offset ? Number(offset) : undefined,
    });
  }

  @Patch()
  async updateMe(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: UpdateMeDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.updateMe(user.id, dto);
  }
}

@Controller('admin/users')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.OWNER, AppRole.ADMIN)
export class AdminUsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  async listUsers(
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('role') role?: string,
  ) {
    return this.usersService.listAllUsers({
      limit: limit ? Number(limit) : 50,
      offset: offset ? Number(offset) : 0,
      role: role && role !== 'all' ? role : undefined,
    });
  }

  @Get('stats')
  async getStats() {
    return this.usersService.getAdminStats();
  }
}
