import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
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

  async createComment(actor: AuthUser, postId: string, dto: CreateCommentDto) {
    const post = await this.prisma.post.findUnique({
      where: { id: postId },
      select: { id: true, projectId: true },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    const comment = await this.prisma.comment.create({
      data: {
        postId,
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
      metadata: { postId, projectId: post.projectId },
    });

    return this.toCommentResponse(comment);
  }

  async listComments(postId: string, query: ListCommentsQuery) {
    const post = await this.prisma.post.findUnique({
      where: { id: postId },
      select: { id: true },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);

    const comments = await this.prisma.comment.findMany({
      where: { postId },
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
        postId: true,
        post: {
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

    const isOwner = actor.roles.includes(AppRole.OWNER);
    const isAdminOwner =
      actor.roles.includes(AppRole.ADMIN) &&
      comment.post.project.ownerAdminId === actor.id;
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
        postId: updated.postId,
        projectId: comment.post.projectId,
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
        postId: true,
        post: {
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

    const isOwner = actor.roles.includes(AppRole.OWNER);
    const isAdminOwner =
      actor.roles.includes(AppRole.ADMIN) &&
      comment.post.project.ownerAdminId === actor.id;
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
        postId: comment.postId,
        projectId: comment.post.projectId,
      },
    });

    return { deleted: true };
  }

  private toCommentResponse(
    comment: Prisma.CommentGetPayload<{
      include: typeof commentInclude;
    }>,
  ) {
    const rawUsername = comment.author.email?.split('@')[0] ?? comment.author.id;
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
