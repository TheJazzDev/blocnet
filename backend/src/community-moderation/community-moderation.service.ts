import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { Prisma } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { normalizePagination } from '../common/utils/pagination.util';
import { PrismaService } from '../prisma/prisma.service';
import {
  COMMUNITY_ACTION_TYPE,
  COMMUNITY_REPORT_STATUS,
  COMMUNITY_REPORT_TARGET_TYPE,
  type CommunityActionType,
  type CommunityReportTargetType,
} from './community-moderation.types';
import { ApplyCommunityMuteDto } from './dto/apply-community-mute.dto';
import { ApplyCommunityRestrictionsDto } from './dto/apply-community-restrictions.dto';
import { ApplyCommunitySuspensionDto } from './dto/apply-community-suspension.dto';
import { ClearCommunityRestrictionsDto } from './dto/clear-community-restrictions.dto';
import { CreateCommunityReportDto } from './dto/create-community-report.dto';
import { IssueCommunityWarningDto } from './dto/issue-community-warning.dto';
import { ListCommunityReportsQuery } from './dto/list-community-reports.query';
import { ReviewCommunityReportDto } from './dto/review-community-report.dto';

const MODERATOR_MAX_MUTE_HOURS = 72;
const ADMIN_MAX_ENFORCEMENT_HOURS = 24 * 30;

@Injectable()
export class CommunityModerationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async createReport(actor: AuthUser, dto: CreateCommunityReportDto) {
    const target = await this.resolveReportTarget(dto.targetType, dto.targetId);

    if (target.targetUserId === actor.id) {
      throw new BadRequestException('You cannot report your own account/content');
    }

    const report = await this.prisma.communityModerationReport.create({
      data: {
        reporterId: actor.id,
        targetType: dto.targetType,
        targetId: dto.targetId,
        targetUserId: target.targetUserId,
        reason: dto.reason,
        details: dto.details?.trim() || null,
      },
      include: {
        reporter: {
          select: {
            id: true,
            email: true,
            displayName: true,
          },
        },
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'community_report.create',
      resourceType: 'community_moderation_report',
      resourceId: report.id,
      metadata: {
        targetType: dto.targetType,
        targetId: dto.targetId,
        targetUserId: target.targetUserId,
        reason: dto.reason,
      },
    });

    return report;
  }

  async listReports(query: ListCommunityReportsQuery) {
    const { offset, limit } = normalizePagination(query.offset, query.limit);

    const where: Prisma.CommunityModerationReportWhereInput = {
      status: query.status,
      targetType: query.targetType,
      ...(query.q
        ? {
            OR: [
              { reason: { contains: query.q, mode: 'insensitive' } },
              { details: { contains: query.q, mode: 'insensitive' } },
              {
                reporter: {
                  OR: [
                    { email: { contains: query.q, mode: 'insensitive' } },
                    { displayName: { contains: query.q, mode: 'insensitive' } },
                  ],
                },
              },
            ],
          }
        : {}),
    };

    const [rows, total] = await Promise.all([
      this.prisma.communityModerationReport.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: offset,
        take: limit,
        include: {
          reporter: {
            select: {
              id: true,
              email: true,
              displayName: true,
            },
          },
          reviewer: {
            select: {
              id: true,
              email: true,
              displayName: true,
            },
          },
          targetUser: {
            select: {
              id: true,
              email: true,
              username: true,
              displayName: true,
            },
          },
        },
      }),
      this.prisma.communityModerationReport.count({ where }),
    ]);

    return {
      data: rows,
      total,
      limit,
      offset,
    };
  }

  async reviewReport(
    actor: AuthUser,
    reportId: string,
    dto: ReviewCommunityReportDto,
  ) {
    this.assertCanReviewReports(actor);

    if (dto.status === COMMUNITY_REPORT_STATUS.open) {
      throw new BadRequestException('Report review status cannot be open');
    }

    const existing = await this.prisma.communityModerationReport.findUnique({
      where: { id: reportId },
      select: {
        id: true,
        status: true,
      },
    });

    if (!existing) {
      throw new NotFoundException('Community report not found');
    }

    const updated = await this.prisma.communityModerationReport.update({
      where: { id: reportId },
      data: {
        status: dto.status,
        reviewedById: actor.id,
        reviewedAt: new Date(),
        resolutionNote: dto.note?.trim() || null,
      },
      include: {
        reporter: {
          select: {
            id: true,
            email: true,
            displayName: true,
          },
        },
        reviewer: {
          select: {
            id: true,
            email: true,
            displayName: true,
          },
        },
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'community_report.review',
      resourceType: 'community_moderation_report',
      resourceId: updated.id,
      metadata: {
        fromStatus: existing.status,
        toStatus: updated.status,
        note: updated.resolutionNote,
      },
    });

    return updated;
  }

  async getUserModerationState(actor: AuthUser, userId: string) {
    this.assertCanTakeCommunityActions(actor);

    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        username: true,
        displayName: true,
        communityWarnCount: true,
        communityLastWarnedAt: true,
        communityMutedUntil: true,
        communitySuspendedUntil: true,
        communityPostingRestrictedUntil: true,
        communityCommentingRestrictedUntil: true,
        roles: {
          select: {
            role: true,
          },
        },
      },
    });

    if (!profile) {
      throw new NotFoundException('User profile not found');
    }

    return {
      ...profile,
      roles: profile.roles.map((entry) => entry.role),
    };
  }

  async issueWarning(
    actor: AuthUser,
    userId: string,
    dto: IssueCommunityWarningDto,
  ) {
    this.assertCanTakeCommunityActions(actor);

    const target = await this.assertActionTargetAllowed(actor, userId);

    const updated = await this.prisma.profile.update({
      where: { id: userId },
      data: {
        communityWarnCount: {
          increment: 1,
        },
        communityLastWarnedAt: new Date(),
      },
      select: {
        communityWarnCount: true,
        communityLastWarnedAt: true,
      },
    });

    await this.recordCommunityAction({
      actionType: COMMUNITY_ACTION_TYPE.warning,
      actorId: actor.id,
      targetUserId: userId,
      reportId: dto.reportId,
      reason: dto.reason,
      previousValue: target.communityLastWarnedAt,
      nextValue: updated.communityLastWarnedAt,
      metadata: {
        warnCount: updated.communityWarnCount,
      },
      auditAction: 'community_user.warning.issue',
    });

    return this.getUserModerationState(actor, userId);
  }

  async applyMute(actor: AuthUser, userId: string, dto: ApplyCommunityMuteDto) {
    this.assertCanTakeCommunityActions(actor);

    const target = await this.assertActionTargetAllowed(actor, userId);
    const maxHours = this.hasCommunityAdminPrivileges(actor)
      ? ADMIN_MAX_ENFORCEMENT_HOURS
      : MODERATOR_MAX_MUTE_HOURS;

    if (dto.durationHours > maxHours) {
      throw new ForbiddenException(
        `Mute duration exceeds your role limit (${maxHours} hours)`,
      );
    }

    const nextValue = this.addHours(dto.durationHours);

    await this.prisma.profile.update({
      where: { id: userId },
      data: {
        communityMutedUntil: nextValue,
      },
    });

    await this.recordCommunityAction({
      actionType: COMMUNITY_ACTION_TYPE.mute,
      actorId: actor.id,
      targetUserId: userId,
      reportId: dto.reportId,
      reason: dto.reason,
      previousValue: target.communityMutedUntil,
      nextValue,
      metadata: {
        durationHours: dto.durationHours,
      },
      auditAction: 'community_user.mute.apply',
    });

    return this.getUserModerationState(actor, userId);
  }

  async applySuspension(
    actor: AuthUser,
    userId: string,
    dto: ApplyCommunitySuspensionDto,
  ) {
    this.assertCanApplySuspension(actor);

    const target = await this.assertActionTargetAllowed(actor, userId);

    if (dto.durationHours > ADMIN_MAX_ENFORCEMENT_HOURS) {
      throw new ForbiddenException(
        `Suspension duration exceeds max limit (${ADMIN_MAX_ENFORCEMENT_HOURS} hours)`,
      );
    }

    const nextValue = this.addHours(dto.durationHours);

    await this.prisma.profile.update({
      where: { id: userId },
      data: {
        communitySuspendedUntil: nextValue,
      },
    });

    await this.recordCommunityAction({
      actionType: COMMUNITY_ACTION_TYPE.suspend,
      actorId: actor.id,
      targetUserId: userId,
      reportId: dto.reportId,
      reason: dto.reason,
      previousValue: target.communitySuspendedUntil,
      nextValue,
      metadata: {
        durationHours: dto.durationHours,
      },
      auditAction: 'community_user.suspension.apply',
    });

    return this.getUserModerationState(actor, userId);
  }

  async applyRestrictions(
    actor: AuthUser,
    userId: string,
    dto: ApplyCommunityRestrictionsDto,
  ) {
    this.assertCanApplyRestrictions(actor);

    if (!dto.postingHours && !dto.commentingHours) {
      throw new BadRequestException(
        'Provide postingHours and/or commentingHours',
      );
    }

    const target = await this.assertActionTargetAllowed(actor, userId);

    if (
      (dto.postingHours ?? 0) > ADMIN_MAX_ENFORCEMENT_HOURS ||
      (dto.commentingHours ?? 0) > ADMIN_MAX_ENFORCEMENT_HOURS
    ) {
      throw new ForbiddenException(
        `Restriction duration exceeds max limit (${ADMIN_MAX_ENFORCEMENT_HOURS} hours)`,
      );
    }

    const postingUntil = dto.postingHours ? this.addHours(dto.postingHours) : null;
    const commentingUntil = dto.commentingHours
      ? this.addHours(dto.commentingHours)
      : null;

    await this.prisma.profile.update({
      where: { id: userId },
      data: {
        communityPostingRestrictedUntil: postingUntil,
        communityCommentingRestrictedUntil: commentingUntil,
      },
    });

    if (postingUntil) {
      await this.recordCommunityAction({
        actionType: COMMUNITY_ACTION_TYPE.restrict_posting,
        actorId: actor.id,
        targetUserId: userId,
        reportId: dto.reportId,
        reason: dto.reason,
        previousValue: target.communityPostingRestrictedUntil,
        nextValue: postingUntil,
        metadata: {
          durationHours: dto.postingHours,
        },
        auditAction: 'community_user.restrict.posting',
      });
    }

    if (commentingUntil) {
      await this.recordCommunityAction({
        actionType: COMMUNITY_ACTION_TYPE.restrict_commenting,
        actorId: actor.id,
        targetUserId: userId,
        reportId: dto.reportId,
        reason: dto.reason,
        previousValue: target.communityCommentingRestrictedUntil,
        nextValue: commentingUntil,
        metadata: {
          durationHours: dto.commentingHours,
        },
        auditAction: 'community_user.restrict.commenting',
      });
    }

    return this.getUserModerationState(actor, userId);
  }

  async clearRestrictions(
    actor: AuthUser,
    userId: string,
    dto: ClearCommunityRestrictionsDto,
  ) {
    this.assertCanApplyRestrictions(actor);

    const target = await this.assertActionTargetAllowed(actor, userId);

    await this.prisma.profile.update({
      where: { id: userId },
      data: {
        communityMutedUntil: null,
        communitySuspendedUntil: null,
        communityPostingRestrictedUntil: null,
        communityCommentingRestrictedUntil: null,
      },
    });

    await this.recordCommunityAction({
      actionType: COMMUNITY_ACTION_TYPE.clear_restrictions,
      actorId: actor.id,
      targetUserId: userId,
      reportId: dto.reportId,
      reason: dto.reason,
      previousValue:
        target.communitySuspendedUntil ??
        target.communityMutedUntil ??
        target.communityPostingRestrictedUntil ??
        target.communityCommentingRestrictedUntil,
      nextValue: null,
      metadata: {
        cleared: true,
      },
      auditAction: 'community_user.restrictions.clear',
    });

    return this.getUserModerationState(actor, userId);
  }

  private addHours(hours: number) {
    return new Date(Date.now() + hours * 60 * 60 * 1000);
  }

  private async recordCommunityAction(input: {
    actionType: CommunityActionType;
    actorId: string;
    targetUserId: string;
    reportId?: string;
    reason?: string;
    previousValue?: Date | null;
    nextValue?: Date | null;
    metadata?: Prisma.InputJsonValue;
    auditAction: string;
  }) {
    const action = await this.prisma.communityModerationAction.create({
      data: {
        actionType: input.actionType,
        actorId: input.actorId,
        targetUserId: input.targetUserId,
        reportId: input.reportId ?? null,
        reason: input.reason ?? null,
        previousValue: input.previousValue ?? null,
        nextValue: input.nextValue ?? null,
        metadata: input.metadata ?? undefined,
      },
    });

    await this.auditLogService.create({
      actorId: input.actorId,
      action: input.auditAction,
      resourceType: 'community_moderation_action',
      resourceId: action.id,
      metadata: {
        actionType: input.actionType,
        targetUserId: input.targetUserId,
        reportId: input.reportId ?? null,
        reason: input.reason ?? null,
        previousValue: input.previousValue?.toISOString() ?? null,
        nextValue: input.nextValue?.toISOString() ?? null,
        metadata: input.metadata ?? null,
      },
    });

    return action;
  }

  private async resolveReportTarget(
    targetType: CommunityReportTargetType,
    targetId: string,
  ): Promise<{ targetUserId: string }> {
    if (targetType === COMMUNITY_REPORT_TARGET_TYPE.community_post) {
      const post = await this.prisma.communityPost.findUnique({
        where: { id: targetId },
        select: { id: true, authorId: true },
      });
      if (!post) {
        throw new NotFoundException('Community post not found');
      }
      return { targetUserId: post.authorId };
    }

    if (targetType === COMMUNITY_REPORT_TARGET_TYPE.community_comment) {
      const comment = await this.prisma.communityPostComment.findUnique({
        where: { id: targetId },
        select: { id: true, authorId: true },
      });

      if (!comment) {
        throw new NotFoundException('Community comment not found');
      }

      return { targetUserId: comment.authorId };
    }

    const profile = await this.prisma.profile.findUnique({
      where: { id: targetId },
      select: { id: true },
    });

    if (!profile) {
      throw new NotFoundException('Target user profile not found');
    }

    return { targetUserId: profile.id };
  }

  private hasRole(actor: AuthUser, role: AppRole): boolean {
    return actor.roles.includes(role);
  }

  private hasGovernancePrivileges(actor: AuthUser): boolean {
    return (
      this.hasRole(actor, AppRole.OWNER) ||
      this.hasRole(actor, AppRole.DEV) ||
      this.hasRole(actor, AppRole.ADMIN)
    );
  }

  private hasCommunityAdminPrivileges(actor: AuthUser): boolean {
    return (
      this.hasGovernancePrivileges(actor) ||
      this.hasRole(actor, AppRole.COMMUNITY_ADMIN)
    );
  }

  private hasCommunityModeratorPrivileges(actor: AuthUser): boolean {
    return (
      this.hasCommunityAdminPrivileges(actor) ||
      this.hasRole(actor, AppRole.COMMUNITY_MODERATOR)
    );
  }

  private assertCanReviewReports(actor: AuthUser) {
    if (!this.hasCommunityModeratorPrivileges(actor)) {
      throw new ForbiddenException('You are not allowed to review reports');
    }
  }

  private assertCanTakeCommunityActions(actor: AuthUser) {
    if (!this.hasCommunityModeratorPrivileges(actor)) {
      throw new ForbiddenException(
        'You are not allowed to take community moderation actions',
      );
    }
  }

  private assertCanApplySuspension(actor: AuthUser) {
    if (!this.hasCommunityAdminPrivileges(actor)) {
      throw new ForbiddenException(
        'Only community admins can apply user suspensions',
      );
    }
  }

  private assertCanApplyRestrictions(actor: AuthUser) {
    if (!this.hasCommunityAdminPrivileges(actor)) {
      throw new ForbiddenException(
        'Only community admins can apply or clear user restrictions',
      );
    }
  }

  private async assertActionTargetAllowed(actor: AuthUser, userId: string) {
    if (actor.id === userId) {
      throw new ForbiddenException('You cannot apply moderation actions to self');
    }

    const target = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        displayName: true,
        communityMutedUntil: true,
        communitySuspendedUntil: true,
        communityPostingRestrictedUntil: true,
        communityCommentingRestrictedUntil: true,
        communityLastWarnedAt: true,
        roles: {
          select: {
            role: true,
          },
        },
      },
    });

    if (!target) {
      throw new NotFoundException('Target user not found');
    }

    const targetRoles = new Set(target.roles.map((entry) => entry.role));

    if (!this.hasGovernancePrivileges(actor)) {
      if (
        targetRoles.has('owner') ||
        targetRoles.has('dev') ||
        targetRoles.has('admin')
      ) {
        throw new ForbiddenException(
          'Community roles cannot sanction governance accounts',
        );
      }
    }

    if (!this.hasCommunityAdminPrivileges(actor)) {
      if (targetRoles.has('community_admin')) {
        throw new ForbiddenException(
          'Community moderators cannot sanction community admins',
        );
      }
    }

    return target;
  }
}
