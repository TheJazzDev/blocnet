import { ContentModerationStatus, Prisma } from '@prisma/client';
import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditLogService } from '../../audit-log/audit-log.service';
import { AppRole } from '../../common/enums/role.enum';
import type { AuthUser } from '../../common/interfaces/auth-user.interface';
import { normalizePagination } from '../../common/utils/pagination.util';
import { PrismaService } from '../../prisma/prisma.service';
import { ListAdminCommunityPostsQuery } from '../dto/list-admin-community-posts.query';
import { ModerateCommunityPostStatusDto } from '../dto/moderate-community-post-status.dto';
import { ListAdminCommunityCommentsQuery } from '../dto/list-admin-community-comments.query';
import { ModerateCommunityCommentStatusDto } from '../dto/moderate-community-comment-status.dto';

@Injectable()
export class AdminCommunityService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async listCommunityPosts(query: ListAdminCommunityPostsQuery) {
    const { offset, limit } = normalizePagination(query.offset, query.limit);

    const where: Prisma.CommunityPostWhereInput = {
      status: query.status,
      topic: query.topic,
      authorId: query.authorId,
      ...(query.q
        ? {
            content: {
              contains: query.q,
              mode: 'insensitive',
            },
          }
        : {}),
    };

    const posts = await this.prisma.communityPost.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      skip: offset,
      take: limit,
      include: {
        author: {
          select: {
            id: true,
            email: true,
            displayName: true,
          },
        },
        moderator: {
          select: {
            id: true,
            email: true,
            displayName: true,
          },
        },
        _count: {
          select: {
            comments: true,
            reactions: true,
          },
        },
      },
    });

    return posts.map((post) => ({
      id: post.id,
      authorId: post.authorId,
      topic: post.topic,
      content: post.content,
      status: post.status,
      author: post.author,
      moderation: {
        moderatedBy: post.moderator,
        moderatedAt: post.moderatedAt,
        moderationReason: post.moderationReason,
      },
      counts: {
        comments: post._count.comments,
        reactions: post._count.reactions,
      },
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
    }));
  }

  async moderateCommunityPostStatus(
    actor: AuthUser,
    postId: string,
    dto: ModerateCommunityPostStatusDto,
  ) {
    this.assertCanSetCommunityStatus(actor, dto.status);

    const existing = await this.prisma.communityPost.findUnique({
      where: { id: postId },
      select: { id: true, status: true },
    });

    if (!existing) {
      throw new NotFoundException('Community post not found');
    }

    const updated = await this.prisma.communityPost.update({
      where: { id: postId },
      data: {
        status: dto.status,
        moderatedBy: actor.id,
        moderatedAt: new Date(),
        moderationReason: dto.reason,
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'community_post.moderate.status',
      resourceType: 'community_post',
      resourceId: updated.id,
      metadata: {
        fromStatus: existing.status,
        toStatus: updated.status,
        reason: dto.reason,
      },
    });

    return updated;
  }

  async listCommunityComments(query: ListAdminCommunityCommentsQuery) {
    const { offset, limit } = normalizePagination(query.offset, query.limit);

    const where: Prisma.CommunityPostCommentWhereInput = {
      status: query.status,
      postId: query.postId,
      authorId: query.authorId,
      ...(query.q
        ? {
            content: {
              contains: query.q,
              mode: 'insensitive',
            },
          }
        : {}),
    };

    const comments = await this.prisma.communityPostComment.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      skip: offset,
      take: limit,
      include: {
        author: {
          select: {
            id: true,
            email: true,
            displayName: true,
          },
        },
        moderator: {
          select: {
            id: true,
            email: true,
            displayName: true,
          },
        },
        post: {
          select: {
            id: true,
            topic: true,
            content: true,
          },
        },
      },
    });

    return comments.map((comment) => ({
      id: comment.id,
      postId: comment.postId,
      authorId: comment.authorId,
      content: comment.content,
      status: comment.status,
      author: comment.author,
      post: {
        id: comment.post.id,
        topic: comment.post.topic,
        preview: comment.post.content.slice(0, 120),
      },
      moderation: {
        moderatedBy: comment.moderator,
        moderatedAt: comment.moderatedAt,
        moderationReason: comment.moderationReason,
      },
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
    }));
  }

  async moderateCommunityCommentStatus(
    actor: AuthUser,
    commentId: string,
    dto: ModerateCommunityCommentStatusDto,
  ) {
    this.assertCanSetCommunityStatus(actor, dto.status);

    const existing = await this.prisma.communityPostComment.findUnique({
      where: { id: commentId },
      select: { id: true, status: true },
    });

    if (!existing) {
      throw new NotFoundException('Community comment not found');
    }

    const updated = await this.prisma.communityPostComment.update({
      where: { id: commentId },
      data: {
        status: dto.status,
        moderatedBy: actor.id,
        moderatedAt: new Date(),
        moderationReason: dto.reason,
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'community_comment.moderate.status',
      resourceType: 'community_post_comment',
      resourceId: updated.id,
      metadata: {
        fromStatus: existing.status,
        toStatus: updated.status,
        reason: dto.reason,
      },
    });

    return updated;
  }

  private assertCanSetCommunityStatus(
    actor: AuthUser,
    status: ContentModerationStatus,
  ) {
    const hasGovernance =
      actor.roles.includes(AppRole.OWNER) ||
      actor.roles.includes(AppRole.DEV) ||
      actor.roles.includes(AppRole.ADMIN);
    const hasCommunityAdmin =
      hasGovernance || actor.roles.includes(AppRole.COMMUNITY_ADMIN);
    const hasCommunityModerator =
      hasCommunityAdmin || actor.roles.includes(AppRole.COMMUNITY_MODERATOR);

    if (!hasCommunityModerator) {
      throw new ForbiddenException('Role is not allowed to moderate community');
    }

    const isFrontlineOnly = !hasCommunityAdmin;
    if (isFrontlineOnly && status === ContentModerationStatus.archived) {
      throw new ForbiddenException(
        'Community moderators can only set status to active or hidden',
      );
    }
  }
}
