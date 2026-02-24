import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UpdateUrgency } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { QuestsService } from '../quests/quests.service';
import { UpdateFollowPreferencesDto } from './dto/update-follow-preferences.dto';

@Injectable()
export class FollowsService {
  private readonly logger = new Logger(FollowsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly auditLogService: AuditLogService,
    private readonly questsService: QuestsService,
  ) {}

  async followProject(userId: string, projectId: string) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { id: true, ownerAdminId: true },
    });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    const existing = await this.prisma.projectFollow.findUnique({
      where: {
        projectId_userId: {
          projectId,
          userId,
        },
      },
      select: { id: true, projectId: true, userId: true, createdAt: true },
    });

    if (existing) {
      return existing;
    }

    const follow = await this.prisma.projectFollow.create({
      data: {
        projectId,
        userId,
      },
    });

    await this.auditLogService.create({
      actorId: userId,
      action: 'project.follow',
      resourceType: 'project_follow',
      resourceId: follow.id,
      metadata: { projectId, ownerAdminId: project.ownerAdminId },
    });

    const followCount = await this.prisma.projectFollow.count({
      where: { userId },
    });
    if (followCount >= 5) {
      await this.triggerQuestAction(userId, 'follow_5_projects');
    }

    return follow;
  }

  async unfollowProject(userId: string, projectId: string) {
    const follow = await this.prisma.projectFollow.findUnique({
      where: {
        projectId_userId: {
          projectId,
          userId,
        },
      },
      select: { id: true },
    });

    if (!follow) {
      return { deleted: false };
    }

    await this.prisma.projectFollow.delete({ where: { id: follow.id } });

    await this.auditLogService.create({
      actorId: userId,
      action: 'project.unfollow',
      resourceType: 'project_follow',
      resourceId: follow.id,
      metadata: { projectId },
    });

    return { deleted: true };
  }

  async getFollowPreferences(userId: string, projectId: string) {
    const enabled = this.configService.get<boolean>(
      'ENABLE_FOLLOW_PREFS',
      true,
    );
    if (!enabled) {
      return {
        projectId,
        userId,
        alertMinUrgency: UpdateUrgency.low,
        mutedUntil: null,
      };
    }

    const follow = await this.prisma.projectFollow.findUnique({
      where: {
        projectId_userId: {
          projectId,
          userId,
        },
      },
      select: {
        projectId: true,
        userId: true,
        alertMinUrgency: true,
        mutedUntil: true,
      },
    });

    if (!follow) {
      return {
        projectId,
        userId,
        alertMinUrgency: UpdateUrgency.low,
        mutedUntil: null,
      };
    }

    return follow;
  }

  async updateFollowPreferences(
    userId: string,
    projectId: string,
    dto: UpdateFollowPreferencesDto,
  ) {
    const enabled = this.configService.get<boolean>(
      'ENABLE_FOLLOW_PREFS',
      true,
    );
    if (!enabled) {
      return this.getFollowPreferences(userId, projectId);
    }

    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { id: true },
    });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    const mutedUntil =
      dto.mutedUntil === null
        ? null
        : dto.mutedUntil
          ? new Date(dto.mutedUntil)
          : undefined;

    const follow = await this.prisma.projectFollow.upsert({
      where: {
        projectId_userId: {
          projectId,
          userId,
        },
      },
      update: {
        alertMinUrgency: dto.alertMinUrgency,
        mutedUntil,
      },
      create: {
        projectId,
        userId,
        alertMinUrgency: dto.alertMinUrgency ?? UpdateUrgency.low,
        mutedUntil: mutedUntil ?? null,
      },
      select: {
        id: true,
        projectId: true,
        userId: true,
        alertMinUrgency: true,
        mutedUntil: true,
      },
    });

    await this.auditLogService.create({
      actorId: userId,
      action: 'follow.preferences.update',
      resourceType: 'project_follow',
      resourceId: follow.id,
      metadata: {
        projectId,
        alertMinUrgency: follow.alertMinUrgency,
        mutedUntil: follow.mutedUntil?.toISOString() ?? null,
      },
    });

    return follow;
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
