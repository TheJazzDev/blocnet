import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { UpdateStatus } from '@prisma/client';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUpdateDto } from './dto/create-update.dto';
import { UpdateUpdateDto } from './dto/update-update.dto';
import { ListUpdatesQuery } from './dto/list-updates.query';
import { NotificationsService } from '../notifications/notifications.service';
import { AuditLogService } from '../audit-log/audit-log.service';
import { BadgesService } from '../badges/badges.service';
import { FcmService } from '../notifications/fcm.service';
import { QuestsService } from '../quests/quests.service';
import { toUpdateResponse, updateInclude } from './updates.mapper';

@Injectable()
export class UpdatesService {
  private readonly logger = new Logger(UpdatesService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly auditLogService: AuditLogService,
    private readonly badgesService: BadgesService,
    private readonly fcmService: FcmService,
    private readonly questsService: QuestsService,
  ) {}

  async createUpdate(actor: AuthUser, projectId: string, dto: CreateUpdateDto) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
    });

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

    const fanout = await this.notificationsService.createForProjectFollowers({
      projectId,
      updateId: update.id,
      actorUserId: actor.id,
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
      userIds: fanout.userIds,
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'update.create',
      resourceType: 'update',
      resourceId: update.id,
      metadata: { projectId },
    });

    // Check and award engagement badges
    await this.badgesService.checkEngagementMilestones(actor.id);
    await this.triggerQuestAction(actor.id, 'first_update');

    return toUpdateResponse(update);
  }

  async listUpdates(query: ListUpdatesQuery) {
    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);

    const updates = await this.prisma.update.findMany({
      where: {
        projectId: query.projectId,
        urgency: query.urgency,
        status: { not: UpdateStatus.hidden },
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
      include: updateInclude,
    });

    return updates.map((update) => toUpdateResponse(update));
  }

  async getUpdate(id: string) {
    const update = await this.prisma.update.findFirst({
      where: {
        id,
        status: { not: UpdateStatus.hidden },
      },
      include: updateInclude,
    });

    if (!update) {
      throw new NotFoundException('Update not found');
    }

    return toUpdateResponse(update);
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
      actor.roles.includes(AppRole.ADMIN) &&
      update.project.ownerAdminId === actor.id;
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

    return toUpdateResponse(updated);
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

    if (actor.roles.includes(AppRole.HUNTER)) {
      const assignment = await this.prisma.projectHunter.findFirst({
        where: {
          projectId,
          hunterId: actor.id,
        },
        select: { id: true },
      });

      if (assignment) {
        return;
      }
    }

    throw new ForbiddenException(
      'Only assigned hunters or owning admins can create updates in this project',
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
