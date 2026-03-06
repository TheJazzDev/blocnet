import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
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
import { ApplyCommunityMuteDto } from './dto/apply-community-mute.dto';
import { ApplyCommunityRestrictionsDto } from './dto/apply-community-restrictions.dto';
import { ApplyCommunitySuspensionDto } from './dto/apply-community-suspension.dto';
import { ClearCommunityRestrictionsDto } from './dto/clear-community-restrictions.dto';
import { CreateCommunityReportDto } from './dto/create-community-report.dto';
import { IssueCommunityWarningDto } from './dto/issue-community-warning.dto';
import { ListCommunityReportsQuery } from './dto/list-community-reports.query';
import { ReviewCommunityReportDto } from './dto/review-community-report.dto';
import { CommunityModerationService } from './community-moderation.service';

@Controller()
@UseGuards(AuthGuard, RolesGuard)
export class CommunityModerationController {
  constructor(
    private readonly communityModerationService: CommunityModerationService,
  ) {}

  @Post('community/reports')
  async createReport(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreateCommunityReportDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.createReport(user, dto);
  }

  @Get('admin/community-moderation/reports')
  @Roles(
    AppRole.OWNER,
    AppRole.DEV,
    AppRole.ADMIN,
    AppRole.COMMUNITY_ADMIN,
    AppRole.COMMUNITY_MODERATOR,
  )
  async listReports(@Query() query: ListCommunityReportsQuery) {
    return this.communityModerationService.listReports(query);
  }

  @Patch('admin/community-moderation/reports/:id')
  @Roles(
    AppRole.OWNER,
    AppRole.DEV,
    AppRole.ADMIN,
    AppRole.COMMUNITY_ADMIN,
    AppRole.COMMUNITY_MODERATOR,
  )
  async reviewReport(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: ReviewCommunityReportDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.reviewReport(user, id, dto);
  }

  @Get('admin/community-moderation/users/:id/state')
  @Roles(
    AppRole.OWNER,
    AppRole.DEV,
    AppRole.ADMIN,
    AppRole.COMMUNITY_ADMIN,
    AppRole.COMMUNITY_MODERATOR,
  )
  async getUserState(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.getUserModerationState(user, id);
  }

  @Post('admin/community-moderation/users/:id/warnings')
  @Roles(
    AppRole.OWNER,
    AppRole.DEV,
    AppRole.ADMIN,
    AppRole.COMMUNITY_ADMIN,
    AppRole.COMMUNITY_MODERATOR,
  )
  async issueWarning(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: IssueCommunityWarningDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.issueWarning(user, id, dto);
  }

  @Post('admin/community-moderation/users/:id/mutes')
  @Roles(
    AppRole.OWNER,
    AppRole.DEV,
    AppRole.ADMIN,
    AppRole.COMMUNITY_ADMIN,
    AppRole.COMMUNITY_MODERATOR,
  )
  async applyMute(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: ApplyCommunityMuteDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.applyMute(user, id, dto);
  }

  @Post('admin/community-moderation/users/:id/suspensions')
  @Roles(
    AppRole.OWNER,
    AppRole.DEV,
    AppRole.ADMIN,
    AppRole.COMMUNITY_ADMIN,
  )
  async applySuspension(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: ApplyCommunitySuspensionDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.applySuspension(user, id, dto);
  }

  @Post('admin/community-moderation/users/:id/restrictions')
  @Roles(
    AppRole.OWNER,
    AppRole.DEV,
    AppRole.ADMIN,
    AppRole.COMMUNITY_ADMIN,
  )
  async applyRestrictions(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: ApplyCommunityRestrictionsDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.applyRestrictions(user, id, dto);
  }

  @Post('admin/community-moderation/users/:id/restrictions/clear')
  @Roles(
    AppRole.OWNER,
    AppRole.DEV,
    AppRole.ADMIN,
    AppRole.COMMUNITY_ADMIN,
  )
  async clearRestrictions(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: ClearCommunityRestrictionsDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.clearRestrictions(user, id, dto);
  }
}
