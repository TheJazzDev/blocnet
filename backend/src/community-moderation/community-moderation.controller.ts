import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { ApiOkResponse, ApiOperation } from '@nestjs/swagger';
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
import { CreateCommunityAppealDto } from './dto/create-community-appeal.dto';
import { CreateCommunityReportDto } from './dto/create-community-report.dto';
import { IssueCommunityWarningDto } from './dto/issue-community-warning.dto';
import {
  InactiveGemQueueResponseDto,
  ResolveInactiveGemResponseDto,
} from './dto/inactive-gem-response.dto';
import { ListInactiveGemsQuery } from './dto/list-inactive-gems.query';
import { ResolveInactiveGemDto } from './dto/resolve-inactive-gem.dto';
import { ListCommunityAppealsQuery } from './dto/list-community-appeals.query';
import { ListCommunityReportsQuery } from './dto/list-community-reports.query';
import { ReviewCommunityAppealDto } from './dto/review-community-appeal.dto';
import { ReviewCommunityReportDto } from './dto/review-community-report.dto';
import { CommunityModerationService } from './community-moderation.service';
import { InactiveGemsModerationService } from './inactive-gems-moderation.service';
import { MyReportsService } from './my-reports.service';

const COMMUNITY_MODERATION_REVIEW_ROLES = [
  AppRole.OWNER,
  AppRole.DEV,
  AppRole.ADMIN,
  AppRole.COMMUNITY_ADMIN,
  AppRole.COMMUNITY_MODERATOR,
] as const;

const COMMUNITY_MODERATION_ESCALATED_ROLES = [
  AppRole.OWNER,
  AppRole.DEV,
  AppRole.ADMIN,
  AppRole.COMMUNITY_ADMIN,
] as const;

@Controller()
@UseGuards(AuthGuard, RolesGuard)
export class CommunityModerationController {
  constructor(
    private readonly communityModerationService: CommunityModerationService,
    private readonly inactiveGems: InactiveGemsModerationService,
    private readonly myReports: MyReportsService,
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

  /** The caller's own reports. Any signed-in member; no staff role. */
  @Get('community/reports/mine')
  @ApiOperation({ summary: 'List the reports the caller has filed' })
  async listMyReports(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListCommunityReportsQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.myReports.listMine(user.id, query);
  }

  @Get(['admin/community-moderation/reports', 'community/moderation/reports'])
  @Roles(...COMMUNITY_MODERATION_REVIEW_ROLES)
  async listReports(@Query() query: ListCommunityReportsQuery) {
    return this.communityModerationService.listReports(query);
  }

  @Patch([
    'admin/community-moderation/reports/:id',
    'community/moderation/reports/:id',
  ])
  @Roles(...COMMUNITY_MODERATION_REVIEW_ROLES)
  async reviewReport(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReviewCommunityReportDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.reviewReport(user, id, dto);
  }

  @Get([
    'admin/community-moderation/users/:id/state',
    'community/moderation/users/:id/state',
  ])
  @Roles(...COMMUNITY_MODERATION_REVIEW_ROLES)
  async getUserState(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.getUserModerationState(user, id);
  }

  @Post([
    'admin/community-moderation/users/:id/warnings',
    'community/moderation/users/:id/warnings',
  ])
  @Roles(...COMMUNITY_MODERATION_REVIEW_ROLES)
  async issueWarning(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: IssueCommunityWarningDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.issueWarning(user, id, dto);
  }

  @Post([
    'admin/community-moderation/users/:id/mutes',
    'community/moderation/users/:id/mutes',
  ])
  @Roles(...COMMUNITY_MODERATION_REVIEW_ROLES)
  async applyMute(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ApplyCommunityMuteDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.applyMute(user, id, dto);
  }

  @Post([
    'admin/community-moderation/users/:id/suspensions',
    'community/moderation/users/:id/suspensions',
  ])
  @Roles(...COMMUNITY_MODERATION_ESCALATED_ROLES)
  async applySuspension(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ApplyCommunitySuspensionDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.applySuspension(user, id, dto);
  }

  @Post([
    'admin/community-moderation/users/:id/restrictions',
    'community/moderation/users/:id/restrictions',
  ])
  @Roles(...COMMUNITY_MODERATION_ESCALATED_ROLES)
  async applyRestrictions(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ApplyCommunityRestrictionsDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.applyRestrictions(user, id, dto);
  }

  @Post([
    'admin/community-moderation/users/:id/restrictions/clear',
    'community/moderation/users/:id/restrictions/clear',
  ])
  @Roles(...COMMUNITY_MODERATION_ESCALATED_ROLES)
  async clearRestrictions(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ClearCommunityRestrictionsDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.clearRestrictions(user, id, dto);
  }

  @Get(['admin/community-moderation/stats', 'community/moderation/stats'])
  @Roles(...COMMUNITY_MODERATION_REVIEW_ROLES)
  @ApiOperation({
    summary:
      'Moderation hub counters. `openInactiveGems` counts gems in the inactive-gems queue: reported, or at least 50 members waiting.',
  })
  async getModerationStats(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const [stats, openInactiveGems] = await Promise.all([
      this.communityModerationService.getModerationStats(),
      this.inactiveGems.countOpen(),
    ]);
    return { ...stats, openInactiveGems };
  }

  @Get('community/moderation/inactive-gems')
  @Roles(...COMMUNITY_MODERATION_REVIEW_ROLES)
  @ApiOperation({
    summary:
      'Gems awaiting a moderator — open inactivity reports, or at least 50 members waiting — most-reported first, then most members waiting.',
  })
  @ApiOkResponse({ type: InactiveGemQueueResponseDto })
  async listInactiveGems(@Query() query: ListInactiveGemsQuery) {
    return this.inactiveGems.listQueue(query);
  }

  @Post('community/moderation/inactive-gems/:projectId/resolve')
  @Roles(...COMMUNITY_MODERATION_REVIEW_ROLES)
  @ApiOperation({
    summary:
      'Close a queued gem with an outcome and a note: closes its open reports and audits the resolution (a waiting-only gem is resolved by the audit entry alone). Does not reassign the gem or delete asks.',
  })
  @ApiOkResponse({ type: ResolveInactiveGemResponseDto })
  async resolveInactiveGem(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId', ParseUUIDPipe) projectId: string,
    @Body() dto: ResolveInactiveGemDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.inactiveGems.resolve(user, projectId, dto);
  }

  @Post(['community/appeals', 'admin/community-moderation/appeals'])
  async createAppeal(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreateCommunityAppealDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.createAppeal(user, dto);
  }

  @Get(['community/appeals', 'admin/community-moderation/appeals'])
  async listAppeals(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListCommunityAppealsQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.listAppeals(user, query);
  }

  @Get([
    'community/moderation/appeals',
    'admin/community-moderation/queue/appeals',
  ])
  @Roles(...COMMUNITY_MODERATION_REVIEW_ROLES)
  async listAppealsQueue(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListCommunityAppealsQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.listAppeals(user, query);
  }

  @Patch([
    'community/moderation/appeals/:id',
    'admin/community-moderation/appeals/:id',
  ])
  @Roles(...COMMUNITY_MODERATION_ESCALATED_ROLES)
  async reviewAppeal(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReviewCommunityAppealDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityModerationService.reviewAppeal(user, id, dto);
  }
}
