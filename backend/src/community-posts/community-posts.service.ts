import {
  CommunityReactionKind,
  CommunityTopic,
  ContentModerationStatus,
  Prisma,
} from '@prisma/client';
import { Injectable, NotFoundException } from '@nestjs/common';
import { AuditLogService } from '../audit-log/audit-log.service';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { PrismaService } from '../prisma/prisma.service';
import {
  buildCommunityPostInclude,
  communityPostCommentInclude,
  toCommunityPostCommentResponse,
  toCommunityPostResponse,
} from './community-posts.mapper';
import { CreateCommunityPostCommentDto } from './dto/create-community-post-comment.dto';
import { CreateCommunityPostDto } from './dto/create-community-post.dto';
import { ListCommunityCommentsQuery } from './dto/list-community-comments.query';
import { ListCommunityPostsQuery } from './dto/list-community-posts.query';
import { ReactCommunityPostDto } from './dto/react-community-post.dto';

@Injectable()
export class CommunityPostsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async listPosts(actor: AuthUser, query: ListCommunityPostsQuery) {
    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);

    const where: Prisma.CommunityPostWhereInput = {
      topic: query.topic,
      authorId: query.authorId,
      status: ContentModerationStatus.active,
    };

    const posts = await this.prisma.communityPost.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
      include: buildCommunityPostInclude(actor.id),
    });

    return posts.map((post) => toCommunityPostResponse(post));
  }

  async getPost(actor: AuthUser, id: string) {
    const post = await this.prisma.communityPost.findFirst({
      where: {
        id,
        status: ContentModerationStatus.active,
      },
      include: buildCommunityPostInclude(actor.id),
    });

    if (!post) {
      throw new NotFoundException('Community post not found');
    }

    return toCommunityPostResponse(post);
  }

  async createPost(actor: AuthUser, dto: CreateCommunityPostDto) {
    const post = await this.prisma.communityPost.create({
      data: {
        authorId: actor.id,
        topic: dto.topic ?? CommunityTopic.general,
        content: dto.content,
      },
      include: buildCommunityPostInclude(actor.id),
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'community_post.create',
      resourceType: 'community_post',
      resourceId: post.id,
      metadata: { topic: post.topic },
    });

    return toCommunityPostResponse(post);
  }

  async listComments(postId: string, query: ListCommunityCommentsQuery) {
    await this.ensurePostIsActive(postId);

    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);

    const comments = await this.prisma.communityPostComment.findMany({
      where: {
        postId,
        status: ContentModerationStatus.active,
      },
      orderBy: { createdAt: 'asc' },
      skip: offset,
      take: limit,
      include: communityPostCommentInclude,
    });

    return comments.map((comment) => toCommunityPostCommentResponse(comment));
  }

  async createComment(
    actor: AuthUser,
    postId: string,
    dto: CreateCommunityPostCommentDto,
  ) {
    await this.ensurePostIsActive(postId);

    const comment = await this.prisma.communityPostComment.create({
      data: {
        postId,
        authorId: actor.id,
        content: dto.content,
      },
      include: communityPostCommentInclude,
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'community_post.comment.create',
      resourceType: 'community_post_comment',
      resourceId: comment.id,
      metadata: { postId },
    });

    return toCommunityPostCommentResponse(comment);
  }

  async reactToPost(
    actor: AuthUser,
    postId: string,
    dto: ReactCommunityPostDto,
  ) {
    await this.ensurePostIsActive(postId);

    const kind = dto.kind ?? CommunityReactionKind.like;

    const existing = await this.prisma.communityPostReaction.findUnique({
      where: {
        postId_userId_kind: {
          postId,
          userId: actor.id,
          kind,
        },
      },
      select: { id: true },
    });

    if (!existing) {
      const reaction = await this.prisma.communityPostReaction.create({
        data: {
          postId,
          userId: actor.id,
          kind,
        },
      });

      await this.auditLogService.create({
        actorId: actor.id,
        action: 'community_post.reaction.add',
        resourceType: 'community_post_reaction',
        resourceId: reaction.id,
        metadata: { postId, kind },
      });
    }

    return this.getPost(actor, postId);
  }

  async removeReaction(
    actor: AuthUser,
    postId: string,
    dto: ReactCommunityPostDto,
  ) {
    await this.ensurePostIsActive(postId);

    const kind = dto.kind ?? CommunityReactionKind.like;

    const reaction = await this.prisma.communityPostReaction.findUnique({
      where: {
        postId_userId_kind: {
          postId,
          userId: actor.id,
          kind,
        },
      },
      select: { id: true },
    });

    if (reaction) {
      await this.prisma.communityPostReaction.delete({
        where: { id: reaction.id },
      });

      await this.auditLogService.create({
        actorId: actor.id,
        action: 'community_post.reaction.remove',
        resourceType: 'community_post_reaction',
        resourceId: reaction.id,
        metadata: { postId, kind },
      });
    }

    return this.getPost(actor, postId);
  }

  async bookmarkPost(actor: AuthUser, postId: string) {
    await this.ensurePostIsActive(postId);

    const existing = await this.prisma.bookmark.findUnique({
      where: {
        userId_communityPostId: {
          userId: actor.id,
          communityPostId: postId,
        },
      },
      select: { id: true },
    });

    if (!existing) {
      const bookmark = await this.prisma.bookmark.create({
        data: {
          userId: actor.id,
          communityPostId: postId,
        },
      });

      await this.auditLogService.create({
        actorId: actor.id,
        action: 'community_post.bookmark.add',
        resourceType: 'bookmark',
        resourceId: bookmark.id,
        metadata: { postId },
      });
    }

    return this.getPost(actor, postId);
  }

  async unbookmarkPost(actor: AuthUser, postId: string) {
    await this.ensurePostIsActive(postId);

    const bookmark = await this.prisma.bookmark.findUnique({
      where: {
        userId_communityPostId: {
          userId: actor.id,
          communityPostId: postId,
        },
      },
      select: { id: true },
    });

    if (bookmark) {
      await this.prisma.bookmark.delete({ where: { id: bookmark.id } });

      await this.auditLogService.create({
        actorId: actor.id,
        action: 'community_post.bookmark.remove',
        resourceType: 'bookmark',
        resourceId: bookmark.id,
        metadata: { postId },
      });
    }

    return this.getPost(actor, postId);
  }

  private async ensurePostIsActive(postId: string) {
    const post = await this.prisma.communityPost.findFirst({
      where: {
        id: postId,
        status: ContentModerationStatus.active,
      },
      select: { id: true },
    });

    if (!post) {
      throw new NotFoundException('Community post not found');
    }
  }
}
