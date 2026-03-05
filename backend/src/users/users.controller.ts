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
import { ReferralsService } from '../referrals/referrals.service';
import { AdminBindUserReferralDto } from './dto/admin-bind-user-referral.dto';
import { AdminDeleteUserDto } from './dto/admin-delete-user.dto';
import { AdminHardDeleteUserDto } from './dto/admin-hard-delete-user.dto';
import { AdminReactivateUserDto } from './dto/admin-reactivate-user.dto';
import { AdminUpdateUserDto } from './dto/admin-update-user.dto';
import { DeactivateAccountDto } from './dto/deactivate-account.dto';
import { UpdateMeDto } from './dto/update-me.dto';
import { UsersService } from './users.service';
import { UsersAdminService } from './users-admin.service';
import { UserDigestService } from './user-digest.service';
import { UpdatesService } from '../updates/updates.service';
import { EdgeEngineService } from '../edge-engine/edge-engine.service';
import { MeRadarService } from '../me-radar/me-radar.service';
import { PrismaService } from '../prisma/prisma.service';

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
  constructor(
    private readonly usersService: UsersService,
    private readonly userDigestService: UserDigestService,
    private readonly updatesService: UpdatesService,
    private readonly edgeEngineService: EdgeEngineService,
    private readonly meRadarService: MeRadarService,
    private readonly prisma: PrismaService,
  ) {}

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

    return this.userDigestService.getDigestSummary(user.id, safeWindowDays);
  }

  @Get('home-bootstrap')
  async getHomeBootstrap(
    @CurrentUser() user: AuthUser | undefined,
    @Query('feedLimit') feedLimit?: string,
    @Query('windowDays') windowDays?: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const parsedFeedLimit = Number(feedLimit);
    const safeFeedLimit =
      Number.isFinite(parsedFeedLimit) && parsedFeedLimit > 0
        ? Math.min(Math.floor(parsedFeedLimit), 200)
        : 80;

    const parsedWindowDays = Number(windowDays);
    const safeWindowDays =
      Number.isFinite(parsedWindowDays) && parsedWindowDays > 0
        ? Math.min(Math.floor(parsedWindowDays), 30)
        : 7;

    let partial = false;
    const timingsMs: Record<string, number> = {};
    const startedAt = Date.now();

    const mePromise = (async () => {
      const t = Date.now();
      try {
        return await this.usersService.getMe(user.id);
      } finally {
        timingsMs.me = Date.now() - t;
      }
    })();

    const updatesPromise = (async () => {
      const t = Date.now();
      try {
        return await this.updatesService.listUpdates(user, {
          limit: safeFeedLimit,
          offset: 0,
        });
      } finally {
        timingsMs.feed = Date.now() - t;
      }
    })();

    const edgeBriefPromise = (async () => {
      const t = Date.now();
      try {
        return await this.edgeEngineService.getBrief(user.id, {
          windowDays: safeWindowDays,
        });
      } catch (_) {
        partial = true;
        return null;
      } finally {
        timingsMs.edgeBrief = Date.now() - t;
      }
    })();

    const radarPromise = (async () => {
      const t = Date.now();
      try {
        return await this.meRadarService.getRadar(user.id);
      } catch (_) {
        partial = true;
        return null;
      } finally {
        timingsMs.radar = Date.now() - t;
      }
    })();

    const unreadCountPromise = (async () => {
      const t = Date.now();
      try {
        return await this.prisma.notification.count({
          where: {
            userId: user.id,
            isRead: false,
          },
        });
      } finally {
        timingsMs.notifications = Date.now() - t;
      }
    })();

    const [
      meSummaryResult,
      feedItemsResult,
      edgeBriefResult,
      radarSummaryResult,
      unreadCountResult,
    ] = await Promise.allSettled([
      mePromise,
      updatesPromise,
      edgeBriefPromise,
      radarPromise,
      unreadCountPromise,
    ]);

    if (meSummaryResult.status === 'rejected') {
      throw meSummaryResult.reason;
    }

    if (feedItemsResult.status === 'rejected') {
      partial = true;
    }
    if (unreadCountResult.status === 'rejected') {
      partial = true;
    }

    const meSummary = meSummaryResult.value;
    const feedItems =
      feedItemsResult.status === 'fulfilled' ? feedItemsResult.value : [];
    const edgeBrief =
      edgeBriefResult.status === 'fulfilled' ? edgeBriefResult.value : null;
    const radarSummary =
      radarSummaryResult.status === 'fulfilled'
        ? radarSummaryResult.value
        : null;
    const unreadCount =
      unreadCountResult.status === 'fulfilled' ? unreadCountResult.value : 0;

    timingsMs.total = Date.now() - startedAt;

    return {
      asOf: new Date().toISOString(),
      cacheTtlSec: 45,
      partial,
      timingsMs,
      meSummary,
      feed: {
        limit: safeFeedLimit,
        offset: 0,
        items: feedItems,
      },
      edgeBrief,
      radar: radarSummary,
      notifications: {
        unreadCount,
      },
    };
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
  constructor(
    private readonly usersService: UsersService,
    private readonly usersAdminService: UsersAdminService,
    private readonly referralsService: ReferralsService,
  ) {}

  @Get()
  async listUsers(
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('role') role?: string,
    @Query('q') q?: string,
    @Query('status') status?: string,
  ) {
    return this.usersAdminService.listAllUsers({
      limit: limit ? Number(limit) : 50,
      offset: offset ? Number(offset) : 0,
      role: role && role !== 'all' ? role : undefined,
      q: q?.trim() || undefined,
      status: status?.trim() || undefined,
    });
  }

  @Get('stats')
  async getStats() {
    return this.usersAdminService.getAdminStats();
  }

  @Get(':id')
  async getUser(@Param('id') id: string) {
    return this.usersAdminService.getAdminUserById(id);
  }

  @Post(':id/referrals/bind')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async bindReferralForUser(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: AdminBindUserReferralDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.referralsService.bindByAdmin(user.id, id, dto.code);
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

    return this.usersAdminService.updateUserByAdmin(user, id, dto);
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

    return this.usersAdminService.deleteUserByAdmin(user, id, dto);
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

    return this.usersAdminService.reactivateUserByOwner(user, id, dto);
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

    return this.usersAdminService.hardDeleteUserByOwner(user, id, dto);
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
