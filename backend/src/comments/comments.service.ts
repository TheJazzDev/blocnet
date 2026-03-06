import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ContentModerationStatus, Prisma, UpdateStatus } from '@prisma/client';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { AppRole } from '../common/enums/role.enum';
import { PrismaService } from '../prisma/prisma.service';
import { AuditLogService } from '../audit-log/audit-log.service';
import { BadgesService } from '../badges/badges.service';
import { BlocksService } from '../blocks/blocks.service';
import { CommunityModerationEnforcementService } from '../community-moderation/community-moderation-enforcement.service';
import { LevelsService } from '../levels/levels.service';
import { QuestsService } from '../quests/quests.service';
import { MentionsService } from '../mentions/mentions.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { ListCommentsQuery } from './dto/list-comments.query';
import { UpdateCommentDto } from './dto/update-comment.dto';

const buildCommentInclude = (viewerId: string) =>
  ({
    author: {
      select: {
        id: true,
        email: true,
        username: true,
        displayName: true,
        avatarUrl: true,
        roles: {
          select: {
            role: true,
          },
        },
        primaryBadge: {
          select: {
            id: true,
            slug: true,
            name: true,
            description: true,
            imageUrl: true,
            category: true,
            rarity: true,
          },
        },
        currentLevel: {
          select: {
            id: true,
            slug: true,
            name: true,
            description: true,
            iconUrl: true,
            level: true,
            requiredBnp: true,
            requiredComments: true,
            requiredDaysActive: true,
            requiredQuests: true,
            requiredUpdates: true,
            requiredProjects: true,
            color: true,
            isActive: true,
            sortOrder: true,
          },
        },
      },
    },
    replyTo: {
      select: {
        id: true,
        content: true,
        author: {
          select: {
            id: true,
            username: true,
            displayName: true,
          },
        },
      },
    },
    reactions: {
      where: {
        userId: viewerId,
        kind: 'like',
      },
      select: {
        id: true,
      },
      take: 1,
    },
    _count: {
      select: {
        reactions: true,
      },
    },
  }) satisfies Prisma.CommentInclude;

type CommentWithRelations = Prisma.CommentGetPayload<{
  include: ReturnType<typeof buildCommentInclude>;
}>;

@Injectable()
export class CommentsService {
  private readonly logger = new Logger(CommentsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly badgesService: BadgesService,
    private readonly blocksService: BlocksService,
    private readonly communityModerationEnforcementService: CommunityModerationEnforcementService,
    private readonly levelsService: LevelsService,
    private readonly questsService: QuestsService,
    private readonly mentionsService: MentionsService,
  ) {}

  async createComment(
    actor: AuthUser,
    updateId: string,
    dto: CreateCommentDto,
  ) {
    await this.communityModerationEnforcementService.assertCanCreateComment(
      actor.id,
    );

    const update = await this.prisma.update.findUnique({
      where: { id: updateId },
      select: { id: true, projectId: true, status: true },
    });

    if (!update) {
      throw new NotFoundException('Update not found');
    }

    if (update.status !== UpdateStatus.published) {
      throw new ForbiddenException('Comments are disabled for this update');
    }

    const comment = await this.prisma.comment.create({
      data: {
        updateId: updateId,
        authorId: actor.id,
        content: dto.content,
        replyToId: dto.replyToId,
      },
      include: buildCommentInclude(actor.id),
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'comment.create',
      resourceType: 'comment',
      resourceId: comment.id,
      metadata: { updateId, projectId: update.projectId },
    });

    // Check and award engagement badges
    await this.badgesService.checkEngagementMilestones(actor.id);
    await this.triggerQuestAction(actor.id, 'first_comment');

    // Process mentions
    await this.mentionsService.createCommentMentions(
      comment.id,
      dto.content,
      actor.id,
    );

    // Trigger level recalculation after comment posted
    try {
      await this.levelsService.updateUserLevel(actor.id);
    } catch (error) {
      this.logger.warn(
        `Failed to update user level after comment: ${error instanceof Error ? error.message : String(error)}`,
      );
    }

    return this.toCommentResponse(comment);
  }

  async listComments(
    actor: AuthUser,
    updateId: string,
    query: ListCommentsQuery,
  ) {
    const update = await this.prisma.update.findUnique({
      where: { id: updateId },
      select: { id: true, status: true },
    });

    if (!update) {
      throw new NotFoundException('Update not found');
    }

    if (update.status !== UpdateStatus.published) {
      throw new ForbiddenException('Comments are disabled for this update');
    }

    const limit = Math.min(query.limit ?? 30, 100);
    const blockedUserIds = await this.blocksService.getBlockedUserIds(actor.id);
    const beforeCreatedAt = query.beforeCreatedAt
      ? new Date(query.beforeCreatedAt)
      : null;

    const where: Prisma.CommentWhereInput = {
      updateId: updateId,
      status: ContentModerationStatus.active,
      ...(blockedUserIds.length > 0
        ? { authorId: { notIn: blockedUserIds } }
        : {}),
      ...(beforeCreatedAt && !Number.isNaN(beforeCreatedAt.getTime())
        ? query.beforeId
          ? {
              OR: [
                { createdAt: { lt: beforeCreatedAt } },
                {
                  AND: [
                    { createdAt: beforeCreatedAt },
                    { id: { lt: query.beforeId } },
                  ],
                },
              ],
            }
          : { createdAt: { lt: beforeCreatedAt } }
        : {}),
    };

    const comments = await this.prisma.comment.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      skip:
        !beforeCreatedAt || Number.isNaN(beforeCreatedAt.getTime())
          ? (query.offset ?? 0)
          : 0,
      take: limit,
      include: buildCommentInclude(actor.id),
    });

    return comments.reverse().map((comment) => this.toCommentResponse(comment));
  }

  async updateComment(actor: AuthUser, id: string, dto: UpdateCommentDto) {
    const comment = await this.prisma.comment.findUnique({
      where: { id },
      select: {
        id: true,
        authorId: true,
        status: true,
        updateId: true,
        update: {
          select: {
            projectId: true,
            project: {
              select: {
                ownerAdminId: true,
              },
            },
          },
        },
      },
    });

    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    if (comment.status !== ContentModerationStatus.active) {
      throw new BadRequestException(
        'Comment is moderated and cannot be edited',
      );
    }

    const isOwner = actor.roles.includes(AppRole.OWNER);
    const isAdminOwner =
      (actor.roles.includes(AppRole.DEV) ||
        actor.roles.includes(AppRole.ADMIN)) &&
      comment.update.project.ownerAdminId === actor.id;
    const isAuthor = comment.authorId === actor.id;

    if (!isOwner && !isAdminOwner && !isAuthor) {
      throw new ForbiddenException('Not allowed to edit this comment');
    }

    const updated = await this.prisma.comment.update({
      where: { id },
      data: {
        content: dto.content,
      },
      include: buildCommentInclude(actor.id),
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'comment.update',
      resourceType: 'comment',
      resourceId: updated.id,
      metadata: {
        updateId: updated.updateId,
        projectId: comment.update.projectId,
      },
    });

    return this.toCommentResponse(updated);
  }

  async deleteComment(actor: AuthUser, id: string) {
    const comment = await this.prisma.comment.findUnique({
      where: { id },
      select: {
        id: true,
        authorId: true,
        status: true,
        updateId: true,
        update: {
          select: {
            projectId: true,
            project: {
              select: {
                ownerAdminId: true,
              },
            },
          },
        },
      },
    });

    if (!comment) {
      return { deleted: false };
    }

    if (comment.status !== ContentModerationStatus.active) {
      throw new BadRequestException(
        'Comment is moderated and cannot be deleted',
      );
    }

    const isOwner = actor.roles.includes(AppRole.OWNER);
    const isAdminOwner =
      (actor.roles.includes(AppRole.DEV) ||
        actor.roles.includes(AppRole.ADMIN)) &&
      comment.update.project.ownerAdminId === actor.id;
    const isAuthor = comment.authorId === actor.id;

    if (!isOwner && !isAdminOwner && !isAuthor) {
      throw new ForbiddenException('Not allowed to delete this comment');
    }

    await this.prisma.comment.delete({ where: { id: comment.id } });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'comment.delete',
      resourceType: 'comment',
      resourceId: comment.id,
      metadata: {
        updateId: comment.updateId,
        projectId: comment.update.projectId,
      },
    });

    return { deleted: true };
  }

  private toCommentResponse(
    comment: CommentWithRelations,
  ) {
    const rawUsername = (comment.author.username ?? '')
      .replaceAll('@', '')
      .trim();
    const normalized = rawUsername.toLowerCase().replace(/[^a-z0-9._-]/g, '');
    const username = `@${normalized || comment.author.id.slice(0, 6)}`;
    const displayName = comment.author.displayName?.trim() || 'Blocnet Member';

    return {
      ...comment,
      likesCount: comment._count.reactions,
      isLiked: comment.reactions.length > 0,
      author: {
        id: comment.author.id,
        displayName: comment.author.displayName,
        username: comment.author.username,
        avatarUrl: comment.author.avatarUrl,
      },
      admin: {
        id: comment.author.id,
        name: displayName,
        username,
        imageUrl: comment.author.avatarUrl ?? '',
        followers: 0,
        roles: comment.author.roles.map((entry) => entry.role),
        primaryBadge: comment.author.primaryBadge ?? null,
        currentLevel: comment.author.currentLevel
          ? {
              id: comment.author.currentLevel.id,
              slug: comment.author.currentLevel.slug,
              name: comment.author.currentLevel.name,
              description: comment.author.currentLevel.description,
              iconUrl: comment.author.currentLevel.iconUrl,
              level: comment.author.currentLevel.level,
              requiredBnp: comment.author.currentLevel.requiredBnp.toString(),
              requiredComments: comment.author.currentLevel.requiredComments,
              requiredDaysActive:
                comment.author.currentLevel.requiredDaysActive,
              requiredQuests: comment.author.currentLevel.requiredQuests,
              requiredUpdates: comment.author.currentLevel.requiredUpdates,
              requiredProjects: comment.author.currentLevel.requiredProjects,
              color: comment.author.currentLevel.color,
              isActive: comment.author.currentLevel.isActive,
              sortOrder: comment.author.currentLevel.sortOrder,
            }
          : null,
      },
    };
  }

  async likeComment(actor: AuthUser, commentId: string) {
    const comment = await this.prisma.comment.findUnique({
      where: { id: commentId },
      select: { id: true, authorId: true },
    });

    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    await this.prisma.commentReaction.upsert({
      where: {
        commentId_userId_kind: {
          commentId,
          userId: actor.id,
          kind: 'like',
        },
      },
      create: {
        commentId,
        userId: actor.id,
        kind: 'like',
      },
      update: {},
    });

    const updated = await this.prisma.comment.findUnique({
      where: { id: commentId },
      include: buildCommentInclude(actor.id),
    });

    return this.toCommentResponse(updated!);
  }

  async unlikeComment(actor: AuthUser, commentId: string) {
    const comment = await this.prisma.comment.findUnique({
      where: { id: commentId },
      select: { id: true },
    });

    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    await this.prisma.commentReaction.deleteMany({
      where: {
        commentId,
        userId: actor.id,
        kind: 'like',
      },
    });

    const updated = await this.prisma.comment.findUnique({
      where: { id: commentId },
      include: buildCommentInclude(actor.id),
    });

    return this.toCommentResponse(updated!);
  }

  private async triggerQuestAction(userId: string, action: string) {
    try {
      await this.questsService.checkAndCompleteByAction(userId, action);
    } catch (error) {
      this.logger.warn(
        `Failed to process auto quest trigger`,
        JSON.stringify({
          action,
          userId,
          error: error instanceof Error ? error.message : String(error),
        }),
      );
    }
  }
}
