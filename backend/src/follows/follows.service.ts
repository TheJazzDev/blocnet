import { Injectable, NotFoundException } from '@nestjs/common';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FollowsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async followProject(userId: string, projectId: string) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { id: true },
    });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    const follow = await this.prisma.projectFollow.upsert({
      where: {
        projectId_userId: {
          projectId,
          userId,
        },
      },
      update: {},
      create: {
        projectId,
        userId,
      },
    });

    await this.auditLogService.create({
      actorId: userId,
      action: 'project.follow',
      resourceType: 'project_follow',
      resourceId: follow.id,
      metadata: { projectId },
    });

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
}
