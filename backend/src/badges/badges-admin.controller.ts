import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RolesGuard } from '../roles/roles.guard';
import { BadgesService } from './badges.service';
import { BadgeResponseDto, UserBadgeResponseDto } from './dto/badge-response.dto';
import { CreateBadgeDto } from './dto/create-badge.dto';
import { GrantBadgeDto } from './dto/grant-badge.dto';

@ApiTags('admin/badges')
@Controller('admin/badges')
@UseGuards(AuthGuard, RolesGuard)
@Roles('admin', 'owner')
export class BadgesAdminController {
  constructor(private readonly badgesService: BadgesService) {}

  @Post()
  @ApiOperation({ summary: 'Admin: Create a new badge' })
  @ApiResponse({
    status: 201,
    description: 'Badge created successfully',
    type: BadgeResponseDto,
  })
  async createBadge(
    @Body() dto: CreateBadgeDto,
    @CurrentUser('id') adminId: string,
  ) {
    return this.badgesService.createBadge(dto, adminId);
  }

  @Get()
  @ApiOperation({ summary: 'Admin: Get all badges including inactive' })
  @ApiResponse({
    status: 200,
    description: 'List of all badges',
    type: [BadgeResponseDto],
  })
  async getAllBadgesAdmin(@Query('includeInactive') includeInactive?: string) {
    return this.badgesService.getAllBadges(includeInactive === 'true');
  }

  @Post('grant')
  @ApiOperation({ summary: 'Admin: Grant a badge to a user' })
  @ApiResponse({
    status: 201,
    description: 'Badge granted successfully',
    type: UserBadgeResponseDto,
  })
  async grantBadge(
    @Body() dto: GrantBadgeDto,
    @CurrentUser('id') adminId: string,
  ) {
    return this.badgesService.grantBadge(dto, adminId);
  }

  @Delete('users/:userId/badges/:badgeSlug')
  @ApiOperation({ summary: 'Admin: Revoke a badge from a user' })
  @ApiResponse({
    status: 200,
    description: 'Badge revoked successfully',
  })
  async revokeBadge(
    @Param('userId') userId: string,
    @Param('badgeSlug') badgeSlug: string,
    @CurrentUser('id') adminId: string,
  ) {
    return this.badgesService.revokeBadge(userId, badgeSlug, adminId);
  }
}
