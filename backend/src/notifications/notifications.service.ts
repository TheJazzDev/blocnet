import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  NotificationType,
  Prisma,
  RoleName,
  UpdateUrgency,
} from '@prisma/client';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { PrismaService } from '../prisma/prisma.service';
import { RuntimeFeatureFlagsService } from '../runtime-flags/runtime-feature-flags.service';
import type { BroadcastTarget } from './dto/broadcast-notification.dto';
import { NotificationEmailService } from './email.service';
import { isCriticalNotificationType } from './notification-preferences.constants';
import { NotificationPreferencesService } from './notification-preferences.service';
import { ListNotificationsQuery } from './dto/list-notifications.query';
import { FcmService } from './fcm.service';
import type {
  NotificationEvent,
  NotifyManyOptions,
} from './types/notification-event.type';

type AuditEventInput = {
  action: string;
  actorId?: string | null;
  resourceId?: string | null;
  metadata?: Prisma.JsonValue | null;
};

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly runtimeFeatureFlagsService: RuntimeFeatureFlagsService,
    private readonly notificationPreferencesService: NotificationPreferencesService,
    private readonly notificationEmailService: NotificationEmailService,
    private readonly fcmService: FcmService,
  ) {}

  async listForUser(userId: string, query: ListNotificationsQuery) {
    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);

    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
    });
  }

  async markAsRead(userId: string, notificationId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: {
        id: notificationId,
        userId,
      },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    return this.prisma.notification.update({
      where: { id: notificationId },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  async createForProjectFollowers(input: {
    projectId: string;
    updateId: string;
    actorUserId?: string;
    title: string;
    body: string;
    urgency: UpdateUrgency;
  }) {
    const userIds = await this.resolveEligibleFollowerUserIds({
      projectId: input.projectId,
      urgency: input.urgency,
    });

    if (userIds.length === 0) {
      return { insertedCount: 0, userIds };
    }

    const events: NotificationEvent[] = userIds.map((userId) => ({
      userId,
      type: NotificationType.project_update,
      actorUserId: input.actorUserId ?? null,
      projectId: input.projectId,
      updateId: input.updateId,
      urgency: input.urgency,
      title: input.title,
      body: input.body,
      payload: {
        projectId: input.projectId,
        updateId: input.updateId,
        urgency: input.urgency,
      } as Prisma.InputJsonValue,
      deeplink: `/updates/${input.updateId}`,
      pushData: {
        type: NotificationType.project_update,
        projectId: input.projectId,
        updateId: input.updateId,
        urgency: input.urgency,
      },
    }));

    const result = await this.notifyMany(events, { push: false });
    return {
      insertedCount: result.insertedCount,
      userIds: result.insertedUserIds,
    };
  }

  async createBroadcast(input: {
    title: string;
    body: string;
    target: BroadcastTarget;
    userIds?: string[];
  }) {
    let resolvedUserIds: string[] = [];

    if (input.target === 'specific' && input.userIds?.length) {
      resolvedUserIds = [...new Set(input.userIds)];
    } else if (input.target === 'hunters') {
      const roles = await this.prisma.userRole.findMany({
        where: { role: { in: ['hunter', 'admin', 'owner'] as any } },
        select: { userId: true },
        distinct: ['userId'],
      });
      resolvedUserIds = roles.map((r) => r.userId);
    } else if (input.target === 'users') {
      const elevated = await this.prisma.userRole.findMany({
        where: { role: { in: ['hunter', 'admin', 'owner'] as any } },
        select: { userId: true },
        distinct: ['userId'],
      });
      const elevatedIds = new Set(elevated.map((r) => r.userId));
      const all = await this.prisma.userRole.findMany({
        where: { role: 'user' as any },
        select: { userId: true },
        distinct: ['userId'],
      });
      resolvedUserIds = all
        .map((r) => r.userId)
        .filter((id) => !elevatedIds.has(id));
    } else {
      const profiles = await this.prisma.profile.findMany({
        select: { id: true },
      });
      resolvedUserIds = profiles.map((p) => p.id);
    }

    if (resolvedUserIds.length === 0) {
      return { insertedCount: 0 };
    }

    const rows = resolvedUserIds.map((userId) => ({
      userId,
      type: NotificationType.system,
      title: input.title,
      body: input.body,
      payload: {
        target: input.target,
      } as Prisma.InputJsonValue,
    }));

    const result = await this.prisma.notification.createMany({
      data: rows,
      skipDuplicates: true,
    });

    return { insertedCount: result.count };
  }

  async notifyMany(events: NotificationEvent[], options?: NotifyManyOptions) {
    const pushEnabled = options?.push !== false;
    const normalized = events
      .filter((event) => event.userId.trim().length > 0)
      .filter(
        (event) =>
          !(
            event.skipSelfNotify &&
            event.actorUserId &&
            event.actorUserId === event.userId
          ),
      );

    const { deliverable } =
      await this.notificationPreferencesService.filterEventsByPreference(
        normalized,
      );

    if (deliverable.length === 0) {
      return {
        insertedCount: 0,
        insertedUserIds: [] as string[],
        sentCount: 0,
        failureCount: 0,
      };
    }

    const inserted: NotificationEvent[] = [];
    const withoutDedupe = deliverable.filter(
      (event) => !event.dedupeKey || event.dedupeKey.trim().length === 0,
    );
    const withDedupe = deliverable.filter((event) =>
      Boolean(event.dedupeKey && event.dedupeKey.trim().length > 0),
    );

    if (withoutDedupe.length > 0) {
      const result = await this.prisma.notification.createMany({
        data: withoutDedupe.map((event) => this.toCreateManyInput(event)),
      });

      if (result.count > 0) {
        inserted.push(...withoutDedupe);
      }
    }

    for (const event of withDedupe) {
      const result = await this.prisma.notification.createMany({
        data: [this.toCreateManyInput(event)],
        skipDuplicates: true,
      });
      if (result.count > 0) {
        inserted.push(event);
      }
    }

    const criticalInserted = inserted.filter((event) =>
      isCriticalNotificationType(event.type),
    );
    if (criticalInserted.length > 0) {
      for (const event of criticalInserted) {
        try {
          await this.notificationEmailService.sendCriticalEmail({
            userId: event.userId,
            title: event.title,
            body: event.body,
            deeplink: event.deeplink ?? null,
          });
        } catch (error) {
          this.logger.warn(
            `Failed to deliver critical email for user ${event.userId}: ${
              error instanceof Error ? error.message : String(error)
            }`,
          );
        }
      }
    }

    if (!pushEnabled || inserted.length === 0) {
      return {
        insertedCount: inserted.length,
        insertedUserIds: [...new Set(inserted.map((event) => event.userId))],
        sentCount: 0,
        failureCount: 0,
      };
    }

    const grouped = new Map<
      string,
      {
        userIds: Set<string>;
        title: string;
        body: string;
        data: Record<string, string | number | boolean | null | undefined>;
      }
    >();

    for (const event of inserted) {
      const data = this.toPushData(event);
      const key = this.toPushGroupKey(event.title, event.body, data);
      const existing = grouped.get(key);
      if (existing) {
        existing.userIds.add(event.userId);
        continue;
      }
      grouped.set(key, {
        userIds: new Set([event.userId]),
        title: event.title,
        body: event.body,
        data,
      });
    }

    let sentCount = 0;
    let failureCount = 0;

    for (const group of grouped.values()) {
      const result = await this.fcmService.sendToUsers({
        userIds: [...group.userIds],
        title: group.title,
        body: group.body,
        data: group.data,
      });
      sentCount += result.sentCount;
      failureCount += result.failureCount ?? 0;
    }

    return {
      insertedCount: inserted.length,
      insertedUserIds: [...new Set(inserted.map((event) => event.userId))],
      sentCount,
      failureCount,
    };
  }

  async emitForAudit(input: AuditEventInput) {
    const enabled = this.configService.get<boolean>(
      'ENABLE_EVENT_NOTIFICATIONS',
      true,
    );
    if (!enabled) {
      return;
    }

    const events = await this.toEventsFromAudit(input);
    if (events.length === 0) {
      return;
    }

    try {
      await this.notifyMany(events, { push: true });
    } catch (error) {
      this.logger.warn(
        `Failed to emit notifications for audit action "${input.action}": ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }

  async resolveEligibleFollowerUserIds(input: {
    projectId: string;
    urgency: UpdateUrgency;
  }) {
    const followPrefsEnabled =
      this.runtimeFeatureFlagsService.isFollowPrefsEnabled();
    const follows = await this.prisma.projectFollow.findMany({
      where: { projectId: input.projectId },
      select: {
        userId: true,
        alertMinUrgency: true,
        mutedUntil: true,
      },
    });

    const now = new Date();
    const incomingRank = urgencyRank(input.urgency);
    return follows
      .filter((follow) => {
        if (!followPrefsEnabled) {
          return true;
        }

        if (follow.mutedUntil && follow.mutedUntil > now) {
          return false;
        }

        const requiredRank = urgencyRank(follow.alertMinUrgency);
        return incomingRank >= requiredRank;
      })
      .map((follow) => follow.userId);
  }

  private toCreateManyInput(
    event: NotificationEvent,
  ): Prisma.NotificationCreateManyInput {
    return {
      userId: event.userId,
      type: event.type,
      actorUserId: event.actorUserId ?? null,
      projectId: event.projectId ?? null,
      updateId: event.updateId ?? null,
      urgency: event.urgency ?? null,
      title: event.title,
      body: event.body,
      payload: event.payload ?? undefined,
      deeplink: event.deeplink ?? null,
      dedupeKey: event.dedupeKey ?? null,
    };
  }

  private toPushData(event: NotificationEvent) {
    return {
      type: event.type,
      projectId: event.projectId,
      updateId: event.updateId,
      actorUserId: event.actorUserId,
      deeplink: event.deeplink,
      ...(event.pushData ?? {}),
    };
  }

  private toPushGroupKey(
    title: string,
    body: string,
    data: Record<string, string | number | boolean | null | undefined>,
  ) {
    const dataKey = Object.entries(data)
      .filter(([, value]) => value != null)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([key, value]) => `${key}:${String(value)}`)
      .join('|');
    return `${title}::${body}::${dataKey}`;
  }

  private async toEventsFromAudit(input: AuditEventInput) {
    const metadata = this.toMetadataRecord(input.metadata);
    const actorId = input.actorId ?? undefined;
    const action = input.action;
    const resourceId = input.resourceId ?? undefined;

    switch (action) {
      case 'profile.follow':
      case 'profile.unfollow':
        return this.profileFollowEvents(action, actorId, resourceId, metadata);
      case 'project.follow':
      case 'project.unfollow':
        return this.projectFollowEvents(action, actorId, resourceId, metadata);
      case 'community_post.reaction.add':
        return this.communityReactionEvents(actorId, resourceId, metadata);
      case 'community_post.bookmark.add':
        return this.communityBookmarkEvents(actorId, resourceId, metadata);
      case 'comment.create':
        return this.updateCommentEvents(actorId, resourceId, metadata);
      case 'project_proposal.create':
        return this.projectProposalSubmittedEvents(actorId, resourceId);
      case 'project_proposal.review':
        return this.projectProposalReviewedEvents(
          actorId,
          resourceId,
          metadata,
        );
      case 'admin_application.create':
        return this.adminApplicationSubmittedEvents(actorId, resourceId);
      case 'admin_application.review':
        return this.adminApplicationReviewedEvents(
          actorId,
          resourceId,
          metadata,
        );
      case 'project.hunter.invite':
        return this.projectInviteReceivedEvents(actorId, resourceId, metadata);
      case 'project.hunter.invite.respond':
        return this.projectInviteRespondedEvents(actorId, resourceId, metadata);
      case 'project.hunter.assign':
        return this.projectAssignmentEvents(actorId, resourceId, metadata);
      case 'admin.user.reactivate':
        return this.userReactivatedEvents(actorId, resourceId, metadata);
      case 'mining.claim':
        return this.miningClaimEvents(actorId, resourceId, metadata);
      case 'referral.bind':
        return this.referralBoundEvents(actorId, resourceId, metadata);
      case 'referral.admin_bind':
        return this.referralAdminBoundEvents(actorId, resourceId, metadata);
      case FinancialAuditActions.LedgerTransferInternal:
        return this.walletInternalTransferEvents(actorId, resourceId, metadata);
      case FinancialAuditActions.DepositCredited:
        return this.walletDepositCreditedEvents(actorId, resourceId, metadata);
      case FinancialAuditActions.WithdrawalRequested:
      case FinancialAuditActions.WithdrawalApproved:
      case FinancialAuditActions.WithdrawalRejected:
      case FinancialAuditActions.WithdrawalBroadcasted:
      case FinancialAuditActions.WithdrawalConfirmed:
      case FinancialAuditActions.WithdrawalReverted:
        return this.walletWithdrawalEvents(
          action,
          actorId,
          resourceId,
          metadata,
        );
      case FinancialAuditActions.KycReviewed:
        return this.walletKycReviewedEvents(actorId, resourceId, metadata);
      case FinancialAuditActions.WalletProvisionReady:
      case FinancialAuditActions.WalletProvisionFailed:
        return this.walletProvisioningEvents(
          action,
          actorId,
          resourceId,
          metadata,
        );
      default:
        if (
          action.startsWith('role.promote.') ||
          action.startsWith('role.demote.')
        ) {
          return this.roleChangedEvents(action, actorId, resourceId, metadata);
        }
        return [];
    }
  }

  private async profileFollowEvents(
    action: 'profile.follow' | 'profile.unfollow',
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const followeeId = this.stringValue(metadata.followeeId);
    if (!followeeId || !actorId || followeeId === actorId) {
      return [];
    }

    const actorName = await this.actorName(actorId);
    const followed = action === 'profile.follow';
    return [
      {
        userId: followeeId,
        type: followed
          ? NotificationType.profile_followed
          : NotificationType.profile_unfollowed,
        actorUserId: actorId,
        title: followed
          ? `${actorName} followed you`
          : `${actorName} unfollowed you`,
        body: followed
          ? 'Your profile just got a new follower.'
          : 'A follower left your profile.',
        payload: {
          action,
          followerUserId: actorId,
          followeeId,
        } as Prisma.InputJsonValue,
        deeplink: '/profile',
        dedupeKey: this.auditDedupeKey(action, resourceId),
      },
    ];
  }

  private async projectFollowEvents(
    action: 'project.follow' | 'project.unfollow',
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const projectId = this.stringValue(metadata.projectId);
    if (!projectId || !actorId) {
      return [];
    }

    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { id: true, name: true, ownerAdminId: true },
    });
    if (!project || project.ownerAdminId === actorId) {
      return [];
    }

    const actorName = await this.actorName(actorId);
    const followed = action === 'project.follow';
    return [
      {
        userId: project.ownerAdminId,
        type: followed
          ? NotificationType.project_followed
          : NotificationType.project_unfollowed,
        actorUserId: actorId,
        projectId: project.id,
        title: followed
          ? `${actorName} followed your project`
          : `${actorName} unfollowed your project`,
        body: project.name,
        payload: {
          action,
          projectId: project.id,
          followerUserId: actorId,
        } as Prisma.InputJsonValue,
        deeplink: `/projects/${project.id}`,
        dedupeKey: this.auditDedupeKey(action, resourceId),
      },
    ];
  }

  private async communityReactionEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const postId = this.stringValue(metadata.postId);
    if (!postId || !actorId) {
      return [];
    }

    const post = await this.prisma.communityPost.findUnique({
      where: { id: postId },
      select: { id: true, authorId: true, content: true },
    });
    if (!post || post.authorId === actorId) {
      return [];
    }

    const actorName = await this.actorName(actorId);
    return [
      {
        userId: post.authorId,
        type: NotificationType.community_liked,
        actorUserId: actorId,
        title: `${actorName} liked your post`,
        body: this.truncate(post.content, 120),
        payload: {
          postId: post.id,
          kind: this.stringValue(metadata.kind) ?? 'like',
        } as Prisma.InputJsonValue,
        deeplink: '/community',
        dedupeKey: this.auditDedupeKey(
          'community_post.reaction.add',
          resourceId,
        ),
      },
    ];
  }

  private async communityBookmarkEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const postId = this.stringValue(metadata.postId);
    if (!postId || !actorId) {
      return [];
    }

    const post = await this.prisma.communityPost.findUnique({
      where: { id: postId },
      select: { id: true, authorId: true, content: true },
    });
    if (!post || post.authorId === actorId) {
      return [];
    }

    const actorName = await this.actorName(actorId);
    return [
      {
        userId: post.authorId,
        type: NotificationType.community_bookmarked,
        actorUserId: actorId,
        title: `${actorName} bookmarked your post`,
        body: this.truncate(post.content, 120),
        payload: {
          postId: post.id,
        } as Prisma.InputJsonValue,
        deeplink: '/community',
        dedupeKey: this.auditDedupeKey(
          'community_post.bookmark.add',
          resourceId,
        ),
      },
    ];
  }

  private async updateCommentEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const updateId = this.stringValue(metadata.updateId);
    if (!updateId || !actorId) {
      return [];
    }

    const update = await this.prisma.update.findUnique({
      where: { id: updateId },
      select: { id: true, projectId: true, title: true, authorId: true },
    });
    if (!update || update.authorId === actorId) {
      return [];
    }

    const actorName = await this.actorName(actorId);
    return [
      {
        userId: update.authorId,
        type: NotificationType.comment_received,
        actorUserId: actorId,
        projectId: update.projectId,
        updateId: update.id,
        title: `${actorName} commented on your update`,
        body: update.title,
        payload: {
          updateId: update.id,
          projectId: update.projectId,
          commentId: resourceId,
        } as Prisma.InputJsonValue,
        deeplink: `/updates/${update.id}`,
        dedupeKey: this.auditDedupeKey('comment.create', resourceId),
      },
    ];
  }

  private async projectProposalSubmittedEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
  ) {
    if (!resourceId) return [];

    const proposal = await this.prisma.projectProposal.findUnique({
      where: { id: resourceId },
      select: { id: true, name: true, applicantId: true },
    });
    if (!proposal) return [];

    const reviewerIds = await this.reviewerUserIds();
    const actorName = actorId ? await this.actorName(actorId) : 'A user';
    return reviewerIds
      .filter((userId) => userId !== actorId)
      .map((userId) => ({
        userId,
        type: NotificationType.project_proposal_submitted,
        actorUserId: actorId ?? null,
        title: 'New project proposal submitted',
        body: `${actorName} submitted ${proposal.name}`,
        payload: {
          proposalId: proposal.id,
          applicantId: proposal.applicantId,
        } as Prisma.InputJsonValue,
        deeplink: '/profile',
        dedupeKey: this.auditDedupeKey('project_proposal.create', resourceId),
      }));
  }

  private async projectProposalReviewedEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const proposalId = resourceId;
    const applicantId = this.stringValue(metadata.applicantId);
    const status = this.stringValue(metadata.status) ?? 'reviewed';
    if (!proposalId || !applicantId || applicantId === actorId) {
      return [];
    }

    const proposal = await this.prisma.projectProposal.findUnique({
      where: { id: proposalId },
      select: { name: true },
    });
    const actorName = actorId ? await this.actorName(actorId) : 'A reviewer';

    return [
      {
        userId: applicantId,
        type: NotificationType.project_proposal_reviewed,
        actorUserId: actorId ?? null,
        title: `Project proposal ${status}`,
        body: proposal?.name ?? 'Your project proposal has been reviewed.',
        payload: {
          proposalId,
          status,
        } as Prisma.InputJsonValue,
        deeplink: '/manage-projects',
        dedupeKey: this.auditDedupeKey('project_proposal.review', proposalId),
        pushData: { actorName },
      },
    ];
  }

  private async adminApplicationSubmittedEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
  ) {
    if (!resourceId) return [];

    const application = await this.prisma.adminApplication.findUnique({
      where: { id: resourceId },
      select: { id: true, targetRole: true },
    });
    if (!application) return [];

    const ownerRows = await this.prisma.userRole.findMany({
      where: { role: RoleName.owner, user: { isDeactivated: false } },
      select: { userId: true },
      distinct: ['userId'],
    });
    const actorName = actorId ? await this.actorName(actorId) : 'A user';

    return ownerRows
      .map((row) => row.userId)
      .filter((userId) => userId !== actorId)
      .map((userId) => ({
        userId,
        type: NotificationType.admin_application_submitted,
        actorUserId: actorId ?? null,
        title: 'New role application submitted',
        body: `${actorName} applied for ${application.targetRole}`,
        payload: {
          applicationId: application.id,
          targetRole: application.targetRole,
        } as Prisma.InputJsonValue,
        deeplink: '/profile',
        dedupeKey: this.auditDedupeKey(
          'admin_application.create',
          application.id,
        ),
      }));
  }

  private async adminApplicationReviewedEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const targetUserId = this.stringValue(metadata.targetUserId);
    if (!resourceId || !targetUserId || targetUserId === actorId) {
      return [];
    }

    const status = this.stringValue(metadata.status) ?? 'reviewed';
    const targetRole = this.stringValue(metadata.targetRole) ?? 'admin';
    return [
      {
        userId: targetUserId,
        type: NotificationType.admin_application_reviewed,
        actorUserId: actorId ?? null,
        title: `Application ${status}`,
        body: `Your ${targetRole} application was ${status}.`,
        payload: {
          applicationId: resourceId,
          targetRole,
          status,
        } as Prisma.InputJsonValue,
        deeplink: '/profile',
        dedupeKey: this.auditDedupeKey('admin_application.review', resourceId),
      },
    ];
  }

  private async projectInviteReceivedEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const hunterId = this.stringValue(metadata.hunterId);
    const projectId = this.stringValue(metadata.projectId);
    if (!hunterId || !projectId || hunterId === actorId) {
      return [];
    }

    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { id: true, name: true },
    });
    const actorName = actorId ? await this.actorName(actorId) : 'A manager';

    return [
      {
        userId: hunterId,
        type: NotificationType.project_invite_received,
        actorUserId: actorId ?? null,
        projectId,
        title: `${actorName} invited you to a project`,
        body: project?.name ?? 'You received a project invite.',
        payload: {
          inviteId: resourceId,
          projectId,
          hunterId,
        } as Prisma.InputJsonValue,
        deeplink: '/manage-projects',
        dedupeKey: this.auditDedupeKey('project.hunter.invite', resourceId),
      },
    ];
  }

  private async projectInviteRespondedEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    if (!resourceId) {
      return [];
    }

    const invite = await this.prisma.projectHunterInvite.findUnique({
      where: { id: resourceId },
      include: {
        project: {
          select: {
            id: true,
            name: true,
            ownerAdminId: true,
          },
        },
      },
    });
    if (!invite) {
      return [];
    }

    const recipients = new Set<string>();
    if (invite.invitedBy) recipients.add(invite.invitedBy);
    if (invite.project.ownerAdminId)
      recipients.add(invite.project.ownerAdminId);
    if (actorId) recipients.delete(actorId);

    if (recipients.size === 0) {
      return [];
    }

    const status = this.stringValue(metadata.status) ?? invite.status;
    const actorName = actorId ? await this.actorName(actorId) : 'A hunter';

    return [...recipients].map((userId) => ({
      userId,
      type: NotificationType.project_invite_responded,
      actorUserId: actorId ?? null,
      projectId: invite.projectId,
      title: `${actorName} ${status} a project invite`,
      body: invite.project.name,
      payload: {
        inviteId: invite.id,
        projectId: invite.projectId,
        status,
      } as Prisma.InputJsonValue,
      deeplink: '/manage-projects',
      dedupeKey: this.auditDedupeKey(
        'project.hunter.invite.respond',
        invite.id,
      ),
    }));
  }

  private async projectAssignmentEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const hunterId = this.stringValue(metadata.hunterId);
    const projectId = this.stringValue(metadata.projectId);
    if (!hunterId || !projectId || hunterId === actorId) {
      return [];
    }

    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { id: true, name: true },
    });
    const actorName = actorId ? await this.actorName(actorId) : 'An admin';

    return [
      {
        userId: hunterId,
        type: NotificationType.project_assignment_changed,
        actorUserId: actorId ?? null,
        projectId,
        title: `You were assigned to ${project?.name ?? 'a project'}`,
        body: `${actorName} assigned you to manage updates.`,
        payload: {
          assignmentId: resourceId,
          projectId,
          hunterId,
        } as Prisma.InputJsonValue,
        deeplink: '/manage-projects',
        dedupeKey: this.auditDedupeKey('project.hunter.assign', resourceId),
      },
    ];
  }

  private async roleChangedEvents(
    action: string,
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const targetUserId = this.stringValue(metadata.targetUserId);
    if (!targetUserId || targetUserId === actorId) {
      return [];
    }

    const role =
      this.stringValue(metadata.role) ?? action.split('.').at(-1) ?? 'role';
    const promoted = action.includes('.promote.');
    const actorName = actorId ? await this.actorName(actorId) : 'System';
    return [
      {
        userId: targetUserId,
        type: NotificationType.role_changed,
        actorUserId: actorId ?? null,
        title: promoted ? 'Role promoted' : 'Role updated',
        body: promoted
          ? `${actorName} promoted you to ${role}.`
          : `${actorName} updated your ${role} access.`,
        payload: {
          action,
          role,
          note: this.stringValue(metadata.note),
        } as Prisma.InputJsonValue,
        deeplink: '/profile',
        dedupeKey: this.auditDedupeKey(action, resourceId),
      },
    ];
  }

  private async userReactivatedEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const targetUserId = this.stringValue(metadata.targetUserId) ?? resourceId;
    if (!targetUserId || targetUserId === actorId) {
      return [];
    }

    return [
      {
        userId: targetUserId,
        type: NotificationType.system,
        actorUserId: actorId ?? null,
        title: 'Account reactivated',
        body: 'Your Blocknet account has been reactivated.',
        payload: {
          action: 'admin.user.reactivate',
          reason: this.stringValue(metadata.reason),
        } as Prisma.InputJsonValue,
        deeplink: '/profile',
        dedupeKey: this.auditDedupeKey('admin.user.reactivate', targetUserId),
      },
    ];
  }

  private async walletInternalTransferEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const toUserId = this.stringValue(metadata.toUserId);
    const amount = this.stringValue(metadata.amount) ?? '0';
    const asset = this.stringValue(metadata.asset) ?? 'BNT';
    const events: NotificationEvent[] = [];

    if (actorId) {
      events.push({
        userId: actorId,
        type: NotificationType.wallet_transfer_sent,
        actorUserId: actorId,
        title: 'Transfer sent',
        body: `You sent ${amount} ${asset}.`,
        payload: {
          transferId: resourceId,
          amount,
          asset,
          toUserId,
        } as Prisma.InputJsonValue,
        deeplink: '/wallet',
        dedupeKey: this.auditDedupeKey(
          FinancialAuditActions.LedgerTransferInternal,
          resourceId,
        ),
      });
    }

    if (toUserId && toUserId !== actorId) {
      events.push({
        userId: toUserId,
        type: NotificationType.wallet_transfer_received,
        actorUserId: actorId ?? null,
        title: 'Transfer received',
        body: `You received ${amount} ${asset}.`,
        payload: {
          transferId: resourceId,
          amount,
          asset,
          fromUserId: actorId,
        } as Prisma.InputJsonValue,
        deeplink: '/wallet',
        dedupeKey: this.auditDedupeKey(
          FinancialAuditActions.LedgerTransferInternal,
          resourceId,
        ),
      });
    }

    return events;
  }

  private async walletDepositCreditedEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    if (!actorId) {
      return [];
    }

    const amount = this.stringValue(metadata.amount) ?? '0';
    const asset = this.stringValue(metadata.asset) ?? 'BNT';
    return [
      {
        userId: actorId,
        type: NotificationType.wallet_deposit_credited,
        actorUserId: null,
        title: 'Deposit credited',
        body: `${amount} ${asset} was credited to your wallet.`,
        payload: {
          depositId: resourceId,
          amount,
          asset,
          txHash: this.stringValue(metadata.txHash),
        } as Prisma.InputJsonValue,
        deeplink: '/wallet',
        dedupeKey: this.auditDedupeKey(
          FinancialAuditActions.DepositCredited,
          resourceId,
        ),
      },
    ];
  }

  private async walletWithdrawalEvents(
    action: string,
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    if (!resourceId) {
      return [];
    }

    const withdrawal = await this.prisma.withdrawalRequest.findUnique({
      where: { id: resourceId },
      select: { id: true, userId: true, amount: true, asset: true },
    });
    if (!withdrawal) {
      return [];
    }

    const textByAction: Record<
      string,
      { type: NotificationType; title: string }
    > = {
      [FinancialAuditActions.WithdrawalRequested]: {
        type: NotificationType.wallet_withdrawal_requested,
        title: 'Withdrawal requested',
      },
      [FinancialAuditActions.WithdrawalApproved]: {
        type: NotificationType.wallet_withdrawal_approved,
        title: 'Withdrawal approved',
      },
      [FinancialAuditActions.WithdrawalRejected]: {
        type: NotificationType.wallet_withdrawal_rejected,
        title: 'Withdrawal rejected',
      },
      [FinancialAuditActions.WithdrawalBroadcasted]: {
        type: NotificationType.wallet_withdrawal_broadcasted,
        title: 'Withdrawal broadcasting',
      },
      [FinancialAuditActions.WithdrawalConfirmed]: {
        type: NotificationType.wallet_withdrawal_confirmed,
        title: 'Withdrawal confirmed',
      },
      [FinancialAuditActions.WithdrawalReverted]: {
        type: NotificationType.wallet_withdrawal_reverted,
        title: 'Withdrawal reverted',
      },
    };
    const mapped = textByAction[action];
    if (!mapped) {
      return [];
    }

    return [
      {
        userId: withdrawal.userId,
        type: mapped.type,
        actorUserId: actorId ?? null,
        title: mapped.title,
        body: `${withdrawal.amount.toString()} ${withdrawal.asset}`,
        payload: {
          withdrawalId: withdrawal.id,
          status: action,
          reason: this.stringValue(metadata.reason),
          txHash: this.stringValue(metadata.txHash),
        } as Prisma.InputJsonValue,
        deeplink: '/wallet/transactions',
        dedupeKey: this.auditDedupeKey(action, withdrawal.id),
      },
    ];
  }

  private async walletKycReviewedEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const userId = this.stringValue(metadata.userId);
    if (!userId) {
      return [];
    }

    const status = this.stringValue(metadata.status) ?? 'reviewed';
    return [
      {
        userId,
        type: NotificationType.wallet_kyc_reviewed,
        actorUserId: actorId ?? null,
        title: 'KYC reviewed',
        body: `Your KYC status is now ${status}.`,
        payload: {
          kycProfileId: resourceId,
          status,
          note: this.stringValue(metadata.note),
        } as Prisma.InputJsonValue,
        deeplink: '/wallet',
        dedupeKey: this.auditDedupeKey(
          FinancialAuditActions.KycReviewed,
          resourceId,
        ),
      },
    ];
  }

  private async walletProvisioningEvents(
    action: string,
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    if (!actorId) {
      return [];
    }

    const ready = action === FinancialAuditActions.WalletProvisionReady;
    return [
      {
        userId: actorId,
        type: ready
          ? NotificationType.wallet_provision_ready
          : NotificationType.wallet_provision_failed,
        actorUserId: null,
        title: ready ? 'Wallet ready' : 'Wallet provisioning failed',
        body: ready
          ? 'Your wallet is ready to use.'
          : (this.stringValue(metadata.reason) ??
            'Wallet provisioning failed. Please retry.'),
        payload: {
          walletId: resourceId,
          address: this.stringValue(metadata.address),
          reason: this.stringValue(metadata.reason),
        } as Prisma.InputJsonValue,
        deeplink: '/wallet',
        dedupeKey: this.auditDedupeKey(action, resourceId),
      },
    ];
  }

  private async miningClaimEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    if (!actorId) {
      return [];
    }

    const points = this.stringValue(metadata.points) ?? '0';
    return [
      {
        userId: actorId,
        type: NotificationType.mining_claimed,
        actorUserId: actorId,
        title: 'Mining points claimed',
        body: `You claimed ${points} points.`,
        payload: {
          sessionId: resourceId,
          points,
        } as Prisma.InputJsonValue,
        deeplink: '/mining',
        dedupeKey: this.auditDedupeKey('mining.claim', resourceId),
      },
    ];
  }

  private async referralBoundEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    if (!actorId) {
      return [];
    }

    return [
      {
        userId: actorId,
        type: NotificationType.referral_bound,
        actorUserId: actorId,
        title: 'Referral connected',
        body: 'Your referral link has been successfully applied.',
        payload: {
          profileId: resourceId,
          referrerId: this.stringValue(metadata.referrerId),
          code: this.stringValue(metadata.code),
        } as Prisma.InputJsonValue,
        deeplink: '/profile',
        dedupeKey: this.auditDedupeKey('referral.bind', resourceId),
      },
    ];
  }

  private async referralAdminBoundEvents(
    actorId: string | undefined,
    resourceId: string | undefined,
    metadata: Record<string, unknown>,
  ) {
    const targetUserId = this.stringValue(metadata.targetUserId) ?? resourceId;
    if (!targetUserId) {
      return [];
    }

    return [
      {
        userId: targetUserId,
        type: NotificationType.referral_admin_bound,
        actorUserId: actorId ?? null,
        title: 'Referral assigned by admin',
        body: 'An admin linked your account to a referral.',
        payload: {
          targetUserId,
          referrerId: this.stringValue(metadata.referrerId),
          code: this.stringValue(metadata.code),
        } as Prisma.InputJsonValue,
        deeplink: '/profile',
        dedupeKey: this.auditDedupeKey('referral.admin_bind', targetUserId),
      },
    ];
  }

  private auditDedupeKey(action: string, resourceId?: string | null) {
    if (!resourceId) return null;
    return `${action}:${resourceId}`;
  }

  private toMetadataRecord(metadata: Prisma.JsonValue | null | undefined) {
    if (metadata && typeof metadata === 'object' && !Array.isArray(metadata)) {
      return metadata as Record<string, unknown>;
    }
    return {};
  }

  private stringValue(value: unknown) {
    if (typeof value === 'number') {
      return Number.isFinite(value) ? value.toString() : null;
    }
    if (typeof value === 'bigint') {
      return value.toString();
    }
    if (typeof value !== 'string') return null;
    const trimmed = value.trim();
    return trimmed.length === 0 ? null : trimmed;
  }

  private truncate(value: string, max = 120) {
    if (value.length <= max) return value;
    return `${value.slice(0, max - 1)}…`;
  }

  private async actorName(actorId: string) {
    const actor = await this.prisma.profile.findUnique({
      where: { id: actorId },
      select: {
        id: true,
        username: true,
        displayName: true,
        email: true,
      },
    });

    if (!actor) return 'Someone';
    if ((actor.displayName?.trim().length ?? 0) > 0)
      return actor.displayName!.trim();
    if ((actor.username?.trim().length ?? 0) > 0) return actor.username!.trim();
    if ((actor.email?.trim().length ?? 0) > 0)
      return actor.email!.split('@')[0];
    return actor.id.slice(0, 8);
  }

  private async reviewerUserIds() {
    const rows = await this.prisma.userRole.findMany({
      where: {
        role: {
          in: [RoleName.owner, RoleName.admin, RoleName.moderator],
        },
        user: {
          isDeactivated: false,
        },
      },
      select: { userId: true },
      distinct: ['userId'],
    });
    return rows.map((row) => row.userId);
  }
}

const urgencyRank = (urgency: UpdateUrgency) => {
  switch (urgency) {
    case UpdateUrgency.high:
      return 3;
    case UpdateUrgency.medium:
      return 2;
    default:
      return 1;
  }
};
