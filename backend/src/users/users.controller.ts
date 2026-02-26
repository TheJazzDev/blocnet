import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UnauthorizedException,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { AdminDeleteUserDto } from './dto/admin-delete-user.dto';
import { AdminHardDeleteUserDto } from './dto/admin-hard-delete-user.dto';
import { AdminReactivateUserDto } from './dto/admin-reactivate-user.dto';
import { AdminUpdateUserDto } from './dto/admin-update-user.dto';
import { DeactivateAccountDto } from './dto/deactivate-account.dto';
import { UpdateMeDto } from './dto/update-me.dto';
import { UsersService } from './users.service';

// Public endpoint — no AuthGuard, called before signup to check uniqueness
@Controller('users')
export class PublicUsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('check-username')
  async checkUsername(@Query('username') username?: string) {
    if (!username?.trim()) {
      throw new BadRequestException('username query param is required');
    }

    const normalized = username.trim().toLowerCase();
    const usernameRegExp = /^[a-z0-9_]{3,24}$/;
    if (!usernameRegExp.test(normalized)) {
      return { available: false, reason: 'invalid_format' };
    }

    const taken = await this.usersService.isUsernameTaken(normalized);
    return { available: !taken };
  }
}

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

  @Get('digest/summary')
  async getDigestSummary(
    @CurrentUser() user: AuthUser | undefined,
    @Query('windowDays') windowDays?: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const parsedWindowDays = windowDays ? Number(windowDays) : undefined;
    const safeWindowDays =
      parsedWindowDays != null && Number.isFinite(parsedWindowDays)
        ? parsedWindowDays
        : undefined;

    return this.usersService.getDigestSummary(user.id, safeWindowDays);
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

  @Post('avatar')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: 5 * 1024 * 1024,
      },
    }),
  )
  async uploadMyAvatar(
    @CurrentUser() user: AuthUser | undefined,
    @UploadedFile()
    file?: {
      buffer: Buffer;
      mimetype: string;
      size: number;
    },
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    if (!file) {
      throw new BadRequestException('Avatar file is required');
    }

    return this.usersService.uploadMyAvatar(user.id, file);
  }
}

@Controller('admin/users')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR)
export class AdminUsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  async listUsers(
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('role') role?: string,
    @Query('q') q?: string,
    @Query('status') status?: string,
  ) {
    return this.usersService.listAllUsers({
      limit: limit ? Number(limit) : 50,
      offset: offset ? Number(offset) : 0,
      role: role && role !== 'all' ? role : undefined,
      q: q?.trim() || undefined,
      status: status?.trim() || undefined,
    });
  }

  @Get('stats')
  async getStats() {
    return this.usersService.getAdminStats();
  }

  @Get(':id')
  async getUser(@Param('id') id: string) {
    return this.usersService.getAdminUserById(id);
  }

  @Patch(':id')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updateUser(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: AdminUpdateUserDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.updateUserByAdmin(user, id, dto);
  }

  @Delete(':id')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async deleteUser(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: AdminDeleteUserDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.deleteUserByAdmin(user, id, dto);
  }

  @Patch(':id/reactivate')
  @Roles(AppRole.OWNER)
  async reactivateUser(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: AdminReactivateUserDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.reactivateUserByOwner(user, id, dto);
  }

  @Delete(':id/hard')
  @Roles(AppRole.OWNER)
  async hardDeleteUser(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: AdminHardDeleteUserDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.hardDeleteUserByOwner(user, id, dto);
  }

  @Post('me/deactivate')
  async deactivateMyAccount(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: DeactivateAccountDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.deactivateAccount(user.id, dto.reason);
  }

  @Post('me/reactivate')
  async reactivateMyAccount(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.reactivateAccount(user.id);
  }
}
