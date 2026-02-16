import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUpdateDto } from './dto/create-update.dto';
import { UpdateUpdateDto } from './dto/update-update.dto';
import { ListUpdatesQuery } from './dto/list-updates.query';
import { NotificationsService } from '../notifications/notifications.service';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FcmService } from '../notifications/fcm.service';
import { Prisma } from '@prisma/client';

const updateInclude = {
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
      primaryTag: {
        select: {
          id: true,
          name: true,
          slug: true,
        },
      },
      ownerAdminId: true,
      createdAt: true,
    },
  },
  secondaryTags: {
    select: {
      secondaryTag: {
        select: {
          id: true,
          name: true,
          slug: true,
        },
      },
    },
  },
} satisfies Prisma.UpdateInclude;

@Injectable()
export class UpdatesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly auditLogService: AuditLogService,
    private readonly fcmService: FcmService,
  ) {}

  async createUpdate(actor: AuthUser, projectId: string, dto: CreateUpdateDto) {
    const project = await this.prisma.project.findUnique({ where: { id: projectId } });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    await this.assertCanCreateUpdate(actor, projectId, project.ownerAdminId);
    await this.assertSecondaryTagsExist(dto.secondaryTagIds);

    const update = await this.prisma.update.create({
      data: {
        projectId,
        authorId: actor.id,
        title: dto.title,
        contentMd: dto.contentMd,
        urgency: dto.urgency,
        secondaryTags: dto.secondaryTagIds?.length
            ? {
                createMany: {
                  data: dto.secondaryTagIds.map((secondaryTagId) => ({
                    secondaryTagId,
                  })),
                  skipDuplicates: true,
                },
              }
            : undefined,
      },
      include: updateInclude,
    });

    const actorName =
      update.author.displayName ?? update.author.email ?? 'Someone';

    await this.notificationsService.createForProjectFollowers({
      projectId,
      updateId: update.id,
      title: `${actorName} posted an update`,
      body: update.title,
      urgency: update.urgency,
    });

    await this.fcmService.sendProjectUpdate({
      projectId,
      updateId: update.id,
      actorName,
      title: `${actorName} posted an update`,
      body: update.title,
      urgency: update.urgency,
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'update.create',
      resourceType: 'update',
      resourceId: update.id,
      metadata: { projectId },
    });

    return this.toUpdateResponse(update);
  }

  async listUpdates(query: ListUpdatesQuery) {
    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);

    const updates = await this.prisma.update.findMany({
      where: {
        projectId: query.projectId,
        urgency: query.urgency,
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
      include: updateInclude,
    });

    return updates.map((update) => this.toUpdateResponse(update));
  }

  async getUpdate(id: string) {
    const update = await this.prisma.update.findUnique({
      where: { id },
      include: updateInclude,
    });

    if (!update) {
      throw new NotFoundException('Update not found');
    }

    return this.toUpdateResponse(update);
  }

  async updateUpdate(actor: AuthUser, id: string, dto: UpdateUpdateDto) {
    const update = await this.prisma.update.findUnique({
      where: { id },
      include: {
        project: {
          select: {
            ownerAdminId: true,
          },
        },
      },
    });

    if (!update) {
      throw new NotFoundException('Update not found');
    }

    const isOwner = actor.roles.includes(AppRole.OWNER);
    const isAdminOwner =
      actor.roles.includes(AppRole.ADMIN) && update.project.ownerAdminId === actor.id;
    const isAuthor = update.authorId === actor.id;

    if (!isOwner && !isAdminOwner && !isAuthor) {
      throw new ForbiddenException('Not allowed to edit this update');
    }

    await this.assertSecondaryTagsExist(dto.secondaryTagIds);

    const updated = await this.prisma.update.update({
      where: { id },
      data: {
        title: dto.title,
        contentMd: dto.contentMd,
        urgency: dto.urgency,
        status: dto.status,
        secondaryTags: dto.secondaryTagIds
            ? {
                deleteMany: {},
                createMany: {
                  data: dto.secondaryTagIds.map((secondaryTagId) => ({
                    secondaryTagId,
                  })),
                  skipDuplicates: true,
                },
              }
            : undefined,
      },
      include: updateInclude,
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'update.update',
      resourceType: 'update',
      resourceId: updated.id,
      metadata: { projectId: updated.projectId },
    });

    return this.toUpdateResponse(updated);
  }

  private async assertCanCreateUpdate(
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
      'Only assigned posters or owning admins can create updates in this project',
    );
  }

  private async assertSecondaryTagsExist(secondaryTagIds?: string[]) {
    const ids = [...new Set(secondaryTagIds ?? [])];
    if (ids.length === 0) return;

    const count = await this.prisma.secondaryTag.count({
      where: { id: { in: ids } },
    });

    if (count !== ids.length) {
      throw new BadRequestException('One or more secondaryTagIds are invalid');
    }
  }

  private toUpdateResponse(
    update: Prisma.UpdateGetPayload<{
      include: typeof updateInclude;
    }>,
  ) {
    const rawUsername = update.author.email?.split('@')[0] ?? update.author.id;
    const normalized = rawUsername
      .toLowerCase()
      .replace(/[^a-z0-9._-]/g, '')
      .trim();
    const fallbackUsername = update.author.id.slice(0, 6);
    const username = `@${normalized || fallbackUsername}`;

    return {
      ...update,
      author: update.author,
      admin: {
        id: update.author.id,
        name: update.author.displayName ?? update.author.email ?? 'Admin',
        username,
        imageUrl: update.author.avatarUrl ?? '',
        followers: 0,
      },
      project: {
        id: update.project.id,
        name: update.project.name,
        description: update.project.description,
        details: update.project.description,
        primaryTagId: update.project.primaryTag.id,
        primaryTag: update.project.primaryTag.name,
        adminId: update.project.ownerAdminId,
        createdAt: update.project.createdAt,
      },
      secondaryTagIds: update.secondaryTags.map((row) => row.secondaryTag.id),
      secondaryTags: update.secondaryTags.map((row) => row.secondaryTag.name),
    };
  }
}
