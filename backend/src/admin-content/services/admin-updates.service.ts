import { Prisma } from '@prisma/client';
import { Injectable, NotFoundException } from '@nestjs/common';
import { AuditLogService } from '../../audit-log/audit-log.service';
import type { AuthUser } from '../../common/interfaces/auth-user.interface';
import { normalizePagination } from '../../common/utils/pagination.util';
import { PrismaService } from '../../prisma/prisma.service';
import { ListAdminUpdatesQuery } from '../dto/list-admin-updates.query';
import { ModerateUpdateStatusDto } from '../dto/moderate-update-status.dto';
import { ListAdminCommentsQuery } from '../dto/list-admin-comments.query';
import { ModerateCommentStatusDto } from '../dto/moderate-comment-status.dto';

@Injectable()
export class AdminUpdatesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async listUpdates(query: ListAdminUpdatesQuery) {
    const { offset, limit } = normalizePagination(query.offset, query.limit);

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
    const { offset, limit } = normalizePagination(query.offset, query.limit);

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
}
