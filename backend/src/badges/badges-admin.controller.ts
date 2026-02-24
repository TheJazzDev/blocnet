import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '../common/guards/auth.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RolesGuard } from '../common/guards/roles.guard';
import { AppRole } from '../common/enums/role.enum';
import { BadgesService } from './badges.service';
import { BadgeResponseDto, UserBadgeResponseDto } from './dto/badge-response.dto';
import { CreateBadgeDto } from './dto/create-badge.dto';
import { UpdateBadgeDto } from './dto/update-badge.dto';
import { GrantBadgeDto } from './dto/grant-badge.dto';

@ApiTags('admin/badges')
@Controller('admin/badges')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.ADMIN, AppRole.OWNER)
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

  @Patch(':badgeId')
  @ApiOperation({ summary: 'Admin: Update a badge' })
  @ApiResponse({
    status: 200,
    description: 'Badge updated successfully',
    type: BadgeResponseDto,
  })
  async updateBadge(
    @Param('badgeId') badgeId: string,
    @Body() dto: UpdateBadgeDto,
    @CurrentUser('id') adminId: string,
  ) {
    return this.badgesService.updateBadge(badgeId, dto, adminId);
  }

  @Post(':badgeId/grant')
  @ApiOperation({ summary: 'Admin: Grant a specific badge to a user' })
  @ApiResponse({
    status: 201,
    description: 'Badge granted successfully',
    type: UserBadgeResponseDto,
  })
  async grantBadgeById(
    @Param('badgeId') badgeId: string,
    @Body() dto: { userId: string; metadata?: Record<string, any> },
    @CurrentUser('id') adminId: string,
  ) {
    const badge = await this.badgesService.getBadgeById(badgeId);
    return this.badgesService.grantBadge(
      { userId: dto.userId, badgeSlug: badge.slug, metadata: dto.metadata },
      adminId,
    );
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
