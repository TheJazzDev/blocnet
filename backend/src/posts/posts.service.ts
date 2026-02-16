import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePostDto } from './dto/create-post.dto';
import { UpdatePostDto } from './dto/update-post.dto';
import { ListPostsQuery } from './dto/list-posts.query';
import { NotificationsService } from '../notifications/notifications.service';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FcmService } from '../notifications/fcm.service';
import { Prisma } from '@prisma/client';

const postInclude = {
  author: {
    select: {
      id: true,
      email: true,
      displayName: true,
      avatarUrl: true,
    },
  },
  project: {
    select: {
      id: true,
      name: true,
      description: true,
      primaryTag: true,
      ownerAdminId: true,
      createdAt: true,
    },
  },
} satisfies Prisma.PostInclude;

@Injectable()
export class PostsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly auditLogService: AuditLogService,
    private readonly fcmService: FcmService,
  ) {}

  async createPost(actor: AuthUser, projectId: string, dto: CreatePostDto) {
    const project = await this.prisma.project.findUnique({ where: { id: projectId } });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    await this.assertCanPost(actor, projectId, project.ownerAdminId);

    const post = await this.prisma.post.create({
      data: {
        projectId,
        authorId: actor.id,
        title: dto.title,
        contentMd: dto.contentMd,
        urgency: dto.urgency,
      },
      include: postInclude,
    });

    await this.notificationsService.createForProjectFollowers({
      projectId,
      postId: post.id,
      title: `Update: ${post.title}`,
      body: post.contentMd.slice(0, 180),
      urgency: post.urgency,
    });

    await this.fcmService.sendProjectPostUpdate({
      projectId,
      postId: post.id,
      title: post.title,
      body: post.contentMd.slice(0, 180),
      urgency: post.urgency,
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'post.create',
      resourceType: 'post',
      resourceId: post.id,
      metadata: { projectId },
    });

    return this.toPostResponse(post);
  }

  async listPosts(query: ListPostsQuery) {
    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);

    const posts = await this.prisma.post.findMany({
      where: {
        projectId: query.projectId,
        urgency: query.urgency,
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
      include: postInclude,
    });

    return posts.map((post) => this.toPostResponse(post));
  }

  async getPost(id: string) {
    const post = await this.prisma.post.findUnique({
      where: { id },
      include: postInclude,
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    return this.toPostResponse(post);
  }

  async updatePost(actor: AuthUser, id: string, dto: UpdatePostDto) {
    const post = await this.prisma.post.findUnique({
      where: { id },
      include: {
        project: {
          select: {
            ownerAdminId: true,
          },
        },
      },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    const isOwner = actor.roles.includes(AppRole.OWNER);
    const isAdminOwner = actor.roles.includes(AppRole.ADMIN) && post.project.ownerAdminId === actor.id;
    const isAuthor = post.authorId === actor.id;

    if (!isOwner && !isAdminOwner && !isAuthor) {
      throw new ForbiddenException('Not allowed to edit this post');
    }

    const updated = await this.prisma.post.update({
      where: { id },
      data: {
        title: dto.title,
        contentMd: dto.contentMd,
        urgency: dto.urgency,
        status: dto.status,
      },
      include: postInclude,
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'post.update',
      resourceType: 'post',
      resourceId: updated.id,
      metadata: { projectId: updated.projectId },
    });

    return this.toPostResponse(updated);
  }

  private async assertCanPost(
    actor: AuthUser,
    projectId: string,
    ownerAdminId: string,
  ) {
    if (actor.roles.includes(AppRole.OWNER)) {
      return;
    }

    if (actor.roles.includes(AppRole.ADMIN) && ownerAdminId === actor.id) {
      return;
    }

    if (actor.roles.includes(AppRole.POSTER)) {
      const assignment = await this.prisma.projectPoster.findFirst({
        where: {
          projectId,
          posterId: actor.id,
        },
        select: { id: true },
      });

      if (assignment) {
        return;
      }
    }

    throw new ForbiddenException(
      'Only assigned posters or owning admins can post to this project',
    );
  }

  private toPostResponse(
    post: Prisma.PostGetPayload<{
      include: typeof postInclude;
    }>,
  ) {
    const rawUsername = post.author.email?.split('@')[0] ?? post.author.id;
    const normalized = rawUsername
      .toLowerCase()
      .replace(/[^a-z0-9._-]/g, '')
      .trim();
    const fallbackUsername = post.author.id.slice(0, 6);
    const username = `@${normalized || fallbackUsername}`;

    return {
      ...post,
      author: post.author,
      admin: {
        id: post.author.id,
        name: post.author.displayName ?? post.author.email ?? 'Admin',
        username,
        imageUrl: post.author.avatarUrl ?? '',
        followers: 0,
      },
      project: {
        id: post.project.id,
        name: post.project.name,
        description: post.project.description,
        details: post.project.description,
        primaryTag: post.project.primaryTag,
        adminId: post.project.ownerAdminId,
        createdAt: post.project.createdAt,
      },
    };
  }
}
