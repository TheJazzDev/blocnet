import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Put,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '../common/guards/auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { BadgesService } from './badges.service';
import {
  BadgeResponseDto,
  UserBadgesResponseDto,
} from './dto/badge-response.dto';
import { SetPrimaryBadgeDto } from './dto/grant-badge.dto';

@ApiTags('badges')
@Controller('badges')
@UseGuards(AuthGuard)
export class BadgesController {
  constructor(private readonly badgesService: BadgesService) {}

  @Get()
  @ApiOperation({ summary: 'Get all available badges' })
  @ApiResponse({
    status: 200,
    description: 'List of all active badges',
    type: [BadgeResponseDto],
  })
  async getAllBadges() {
    return this.badgesService.getAllBadges();
  }

  @Get('users/:userId')
  @ApiOperation({ summary: 'Get badges earned by a user' })
  @ApiResponse({
    status: 200,
    description: 'User badges',
    type: UserBadgesResponseDto,
  })
  async getUserBadges(@Param('userId') userId: string) {
    return this.badgesService.getUserBadges(userId);
  }

  @Get('me')
  @ApiOperation({ summary: 'Get my badges' })
  @ApiResponse({
    status: 200,
    description: 'Current user badges',
    type: UserBadgesResponseDto,
  })
  async getMyBadges(@CurrentUser('id') userId: string) {
    return this.badgesService.getUserBadges(userId);
  }

  @Put('me/primary')
  @ApiOperation({ summary: 'Set my primary badge' })
  @ApiResponse({
    status: 200,
    description: 'Primary badge set successfully',
    type: BadgeResponseDto,
  })
  async setMyPrimaryBadge(
    @CurrentUser('id') userId: string,
    @Body() dto: SetPrimaryBadgeDto,
  ) {
    return this.badgesService.setUserPrimaryBadge(userId, dto.badgeId);
  }

  @Patch('me/primary')
  @ApiOperation({
    summary: 'Set my primary badge (PATCH compatibility alias)',
  })
  @ApiResponse({
    status: 200,
    description: 'Primary badge set successfully',
    type: BadgeResponseDto,
  })
  async patchMyPrimaryBadge(
    @CurrentUser('id') userId: string,
    @Body() dto: SetPrimaryBadgeDto,
  ) {
    return this.badgesService.setUserPrimaryBadge(userId, dto.badgeId);
  }
}
