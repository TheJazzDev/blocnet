import { Prisma, ProjectStatus } from '@prisma/client';
import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditLogService } from '../audit-log/audit-log.service';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { PrismaService } from '../prisma/prisma.service';
import { ListAdminCommentsQuery } from './dto/list-admin-comments.query';
import { ListAdminCommunityCommentsQuery } from './dto/list-admin-community-comments.query';
import { ListAdminCommunityPostsQuery } from './dto/list-admin-community-posts.query';
import { ListAdminProjectsQuery } from './dto/list-admin-projects.query';
import { ListAdminUpdatesQuery } from './dto/list-admin-updates.query';
import { ModerateCommentStatusDto } from './dto/moderate-comment-status.dto';
import { ModerateCommunityCommentStatusDto } from './dto/moderate-community-comment-status.dto';
import { ModerateCommunityPostStatusDto } from './dto/moderate-community-post-status.dto';
import { ModerateProjectStatusDto } from './dto/moderate-project-status.dto';
import { ModerateUpdateStatusDto } from './dto/moderate-update-status.dto';

@Injectable()
export class AdminContentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async listProjects(query: ListAdminProjectsQuery) {
    const { offset, limit } = this.normalizePagination(
      query.offset,
      query.limit,
    );

    const where: Prisma.ProjectWhereInput = {
      status: query.status,
      ...(query.q
        ? {
            OR: [
              { name: { contains: query.q, mode: 'insensitive' } },
              { slug: { contains: query.q.toLowerCase() } },
              { symbol: { contains: query.q.toUpperCase() } },
              { description: { contains: query.q, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const projects = await this.prisma.project.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      skip: offset,
      take: limit,
      include: {
        ownerAdmin: {
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
        primaryTag: {
          select: {
            id: true,
            name: true,
          },
        },
        _count: {
          select: {
            updates: true,
            follows: true,
          },
        },
      },
    });

    return projects.map((project) => ({
      id: project.id,
      name: project.name,
      symbol: project.symbol,
      status: project.status,
      description: project.description,
      slug: project.slug,
      primaryTag: project.primaryTag,
      owner: project.ownerAdmin,
      moderation: {
        moderatedBy: project.moderator,
        moderatedAt: project.moderatedAt,
        moderationReason: project.moderationReason,
      },
      counts: {
        updates: project._count.updates,
        followers: project._count.follows,
      },
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
    }));
  }

  async moderateProjectStatus(
    actor: AuthUser,
    projectId: string,
    dto: ModerateProjectStatusDto,
  ) {
    if (dto.status === ProjectStatus.paused && this.isModeratorOnly(actor)) {
      throw new ForbiddenException(
        'Moderators can only set project status to active, hidden, or archived',
      );
    }

    const existing = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { id: true, status: true },
    });

    if (!existing) {
      throw new NotFoundException('Project not found');
    }

    const updated = await this.prisma.project.update({
      where: { id: projectId },
      data: {
        status: dto.status,
        moderatedBy: actor.id,
        moderatedAt: new Date(),
        moderationReason: dto.reason,
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.moderate.status',
      resourceType: 'project',
      resourceId: updated.id,
      metadata: {
        fromStatus: existing.status,
        toStatus: updated.status,
        reason: dto.reason,
      },
    });

    return updated;
  }

  async listUpdates(query: ListAdminUpdatesQuery) {
    const { offset, limit } = this.normalizePagination(
      query.offset,
      query.limit,
    );

    const where: Prisma.UpdateWhereInput = {
      status: query.status,
      projectId: query.projectId,
      authorId: query.authorId,
      ...(query.q
        ? {
            OR: [
              { title: { contains: query.q, mode: 'insensitive' } },
              { contentMd: { contains: query.q, mode: 'insensitive' } },
              { project: { name: { contains: query.q, mode: 'insensitive' } } },
            ],
          }
        : {}),
    };

    const updates = await this.prisma.update.findMany({
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
        project: {
          select: {
            id: true,
            name: true,
            slug: true,
          },
        },
      },
    });

    return updates.map((update) => ({
      id: update.id,
      projectId: update.projectId,
      authorId: update.authorId,
      title: update.title,
      contentMd: update.contentMd,
      urgency: update.urgency,
      status: update.status,
      author: update.author,
      project: update.project,
      moderation: {
        moderatedBy: update.moderator,
        moderatedAt: update.moderatedAt,
        moderationReason: update.moderationReason,
      },
      createdAt: update.createdAt,
      updatedAt: update.updatedAt,
    }));
  }

  async moderateUpdateStatus(
    actor: AuthUser,
    updateId: string,
    dto: ModerateUpdateStatusDto,
  ) {
    const existing = await this.prisma.update.findUnique({
      where: { id: updateId },
      select: { id: true, status: true },
    });

    if (!existing) {
      throw new NotFoundException('Update not found');
    }

    const updated = await this.prisma.update.update({
      where: { id: updateId },
      data: {
        status: dto.status,
        moderatedBy: actor.id,
        moderatedAt: new Date(),
        moderationReason: dto.reason,
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'update.moderate.status',
      resourceType: 'update',
      resourceId: updated.id,
      metadata: {
        fromStatus: existing.status,
        toStatus: updated.status,
        reason: dto.reason,
      },
    });

    return updated;
  }

  async listComments(query: ListAdminCommentsQuery) {
    const { offset, limit } = this.normalizePagination(
      query.offset,
      query.limit,
    );

    const where: Prisma.CommentWhereInput = {
      status: query.status,
      updateId: query.updateId,
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

    const comments = await this.prisma.comment.findMany({
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
        update: {
          select: {
            id: true,
            title: true,
            project: {
              select: {
                id: true,
                name: true,
              },
            },
          },
        },
      },
    });

    return comments.map((comment) => ({
      id: comment.id,
      updateId: comment.updateId,
      authorId: comment.authorId,
      content: comment.content,
      status: comment.status,
      author: comment.author,
      update: comment.update,
      moderation: {
        moderatedBy: comment.moderator,
        moderatedAt: comment.moderatedAt,
        moderationReason: comment.moderationReason,
      },
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
    }));
  }

  async moderateCommentStatus(
    actor: AuthUser,
    commentId: string,
    dto: ModerateCommentStatusDto,
  ) {
    const existing = await this.prisma.comment.findUnique({
      where: { id: commentId },
      select: { id: true, status: true },
    });

    if (!existing) {
      throw new NotFoundException('Comment not found');
    }

    const updated = await this.prisma.comment.update({
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
      action: 'comment.moderate.status',
      resourceType: 'comment',
      resourceId: updated.id,
      metadata: {
        fromStatus: existing.status,
        toStatus: updated.status,
        reason: dto.reason,
      },
    });

    return updated;
  }

  async listCommunityPosts(query: ListAdminCommunityPostsQuery) {
    const { offset, limit } = this.normalizePagination(
      query.offset,
      query.limit,
    );

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
    const { offset, limit } = this.normalizePagination(
      query.offset,
      query.limit,
    );

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

  private normalizePagination(offset?: number, limit?: number) {
    return {
      offset: Math.max(offset ?? 0, 0),
      limit: Math.min(Math.max(limit ?? 30, 1), 100),
    };
  }

  private isModeratorOnly(actor: AuthUser) {
    const isOwner = actor.roles.includes(AppRole.OWNER);
    const isAdmin = actor.roles.includes(AppRole.ADMIN);
    const isModerator = actor.roles.includes(AppRole.MODERATOR);
    return !isOwner && !isAdmin && isModerator;
  }
}
