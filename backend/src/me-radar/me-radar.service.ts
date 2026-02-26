import { Injectable, NotFoundException } from '@nestjs/common';
import { ProjectStatus, UpdateStatus, UpdateUrgency } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { RuntimeFeatureFlagsService } from '../runtime-flags/runtime-feature-flags.service';

type ActiveProject = {
  projectId: string;
  projectName: string;
  newCount: number;
  highCount: number;
  lastUpdateAt: Date | null;
};

@Injectable()
export class MeRadarService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly runtimeFeatureFlagsService: RuntimeFeatureFlagsService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async getRadar(userId: string) {
    const enabled = this.runtimeFeatureFlagsService.isAlphaRadarEnabled();
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        id: true,
        homeFeedLastSeenAt: true,
        follows: {
          select: {
            projectId: true,
          },
        },
      },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    const asOf = new Date();
    const lastSeenAt = profile.homeFeedLastSeenAt;
    if (!enabled) {
      return {
        asOf,
        lastSeenAt,
        newUpdatesCount: 0,
        highUrgencyCount: 0,
        activeProjects: [] as ActiveProject[],
      };
    }

    const followedProjectIds = profile.follows.map(
      (follow) => follow.projectId,
    );
    if (followedProjectIds.length === 0) {
      return {
        asOf,
        lastSeenAt,
        newUpdatesCount: 0,
        highUrgencyCount: 0,
        activeProjects: [] as ActiveProject[],
      };
    }

    const baselineSeenAt =
      lastSeenAt ?? new Date(asOf.getTime() - 7 * 24 * 60 * 60 * 1000);
    const updates = await this.prisma.update.findMany({
      where: {
        projectId: { in: followedProjectIds },
        status: { not: UpdateStatus.hidden },
        createdAt: { gt: baselineSeenAt },
        project: {
          status: { not: ProjectStatus.hidden },
        },
      },
      select: {
        projectId: true,
        urgency: true,
        createdAt: true,
        project: {
          select: {
            name: true,
          },
        },
      },
    });

    const highUrgencyCount = updates.filter(
      (update) => update.urgency === UpdateUrgency.high,
    ).length;

    const activeMap = new Map<string, ActiveProject>();
    for (const update of updates) {
      const existing = activeMap.get(update.projectId);
      const isHigh = update.urgency === UpdateUrgency.high;

      if (!existing) {
        activeMap.set(update.projectId, {
          projectId: update.projectId,
          projectName: update.project.name,
          newCount: 1,
          highCount: isHigh ? 1 : 0,
          lastUpdateAt: update.createdAt,
        });
      } else {
        existing.newCount += 1;
        existing.highCount += isHigh ? 1 : 0;
        if (
          !existing.lastUpdateAt ||
          update.createdAt.getTime() > existing.lastUpdateAt.getTime()
        ) {
          existing.lastUpdateAt = update.createdAt;
        }
      }
    }

    const activeProjects = Array.from(activeMap.values())
      .sort((a, b) => {
        const byHigh = b.highCount - a.highCount;
        if (byHigh !== 0) return byHigh;

        const byNew = b.newCount - a.newCount;
        if (byNew !== 0) return byNew;

        return (
          (b.lastUpdateAt?.getTime() ?? 0) - (a.lastUpdateAt?.getTime() ?? 0)
        );
      })
      .slice(0, 6);

    return {
      asOf,
      lastSeenAt,
      newUpdatesCount: updates.length,
      highUrgencyCount,
      activeProjects,
    };
  }

  async ack(userId: string, seenAt?: string) {
    const timestamp = seenAt ? new Date(seenAt) : new Date();
    const profile = await this.prisma.profile.update({
      where: { id: userId },
      data: {
        homeFeedLastSeenAt: timestamp,
      },
      select: {
        id: true,
        homeFeedLastSeenAt: true,
      },
    });

    await this.auditLogService.create({
      actorId: userId,
      action: 'radar.ack',
      resourceType: 'profile',
      resourceId: profile.id,
      metadata: { seenAt: timestamp.toISOString() },
    });

    return {
      ok: true,
      seenAt: profile.homeFeedLastSeenAt,
    };
  }
}
