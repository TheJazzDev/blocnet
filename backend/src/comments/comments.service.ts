import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ContentModerationStatus, Prisma, UpdateStatus } from '@prisma/client';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { AppRole } from '../common/enums/role.enum';
import { PrismaService } from '../prisma/prisma.service';
import { AuditLogService } from '../audit-log/audit-log.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { ListCommentsQuery } from './dto/list-comments.query';
import { UpdateCommentDto } from './dto/update-comment.dto';

const commentInclude = {
  author: {
    select: {
      id: true,
      email: true,
      displayName: true,
      avatarUrl: true,
    },
  },
} satisfies Prisma.CommentInclude;

@Injectable()
export class CommentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async createComment(
    actor: AuthUser,
    updateId: string,
    dto: CreateCommentDto,
  ) {
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
      },
      include: commentInclude,
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'comment.create',
      resourceType: 'comment',
      resourceId: comment.id,
      metadata: { updateId, projectId: update.projectId },
    });

    return this.toCommentResponse(comment);
  }

  async listComments(updateId: string, query: ListCommentsQuery) {
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

    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);

    const comments = await this.prisma.comment.findMany({
      where: {
        updateId: updateId,
        status: ContentModerationStatus.active,
      },
      orderBy: { createdAt: 'asc' },
      skip: offset,
      take: limit,
      include: commentInclude,
    });

    return comments.map((comment) => this.toCommentResponse(comment));
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
      actor.roles.includes(AppRole.ADMIN) &&
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
      include: commentInclude,
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
      actor.roles.includes(AppRole.ADMIN) &&
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
    comment: Prisma.CommentGetPayload<{
      include: typeof commentInclude;
    }>,
  ) {
    const rawUsername =
      comment.author.email?.split('@')[0] ?? comment.author.id;
    const normalized = rawUsername
      .toLowerCase()
      .replace(/[^a-z0-9._-]/g, '')
      .trim();
    const username = `@${normalized || comment.author.id.slice(0, 6)}`;

    return {
      ...comment,
      author: {
        id: comment.author.id,
        email: comment.author.email,
        displayName: comment.author.displayName,
        avatarUrl: comment.author.avatarUrl,
      },
      admin: {
        id: comment.author.id,
        name: comment.author.displayName ?? comment.author.email ?? 'User',
        username,
        imageUrl: comment.author.avatarUrl ?? '',
        followers: 0,
      },
    };
  }
}
