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

    return post;
  }

  async listPosts(query: ListPostsQuery) {
    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);

    return this.prisma.post.findMany({
      where: {
        projectId: query.projectId,
        urgency: query.urgency,
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
    });
  }

  async getPost(id: string) {
    const post = await this.prisma.post.findUnique({ where: { id } });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    return post;
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
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'post.update',
      resourceType: 'post',
      resourceId: updated.id,
      metadata: { projectId: updated.projectId },
    });

    return updated;
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
}
