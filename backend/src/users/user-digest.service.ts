import { Injectable, NotFoundException } from '@nestjs/common';
import {
  ContentModerationStatus,
  ProjectStatus,
  UpdateStatus,
  UpdateUrgency,
} from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { RuntimeFeatureFlagsService } from '../runtime-flags/runtime-feature-flags.service';

const DIGEST_VIEW_AUDIT_COOLDOWN_MS = 60 * 60 * 1000;

@Injectable()
export class UserDigestService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly runtimeFeatureFlagsService: RuntimeFeatureFlagsService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async getDigestSummary(
    userId: string,
    windowDays = 7,
    options?: {
      skipAudit?: boolean;
    },
  ) {
    const digestEnabled =
      this.runtimeFeatureFlagsService.isWeeklyDigestEnabled();
    const boundedWindow = Math.min(Math.max(windowDays, 1), 30);
    if (!digestEnabled) {
      return {
        windowDays: boundedWindow,
        missedHighUrgency: [],
        activeProjects: [],
        topCommunityPosts: [],
      };
    }

    const since = new Date(Date.now() - boundedWindow * 24 * 60 * 60 * 1000);

    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
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

    const followedProjectIds = profile.follows.map(
      (follow) => follow.projectId,
    );
    if (followedProjectIds.length === 0) {
      if (!options?.skipAudit) {
        await this.logDigestViewAuditIfDue(userId, {
          windowDays: boundedWindow,
          emptyFollowSet: true,
        });
      }

      return {
        windowDays: boundedWindow,
        missedHighUrgency: [],
        activeProjects: [],
        topCommunityPosts: [],
      };
    }

    const [missedHighUrgencyRows, activeProjectRows, communityRows] =
      await Promise.all([
        this.prisma.update.findMany({
          where: {
            projectId: { in: followedProjectIds },
            status: { not: UpdateStatus.hidden },
            urgency: UpdateUrgency.high,
            createdAt: {
              gte: since,
              ...(profile.homeFeedLastSeenAt
                ? { gt: profile.homeFeedLastSeenAt }
                : {}),
            },
          },
          orderBy: { createdAt: 'desc' },
          take: 20,
          select: {
            id: true,
            title: true,
            urgency: true,
            createdAt: true,
            projectId: true,
            project: {
              select: {
                name: true,
              },
            },
          },
        }),
        this.prisma.project.findMany({
          where: {
            id: { in: followedProjectIds },
            status: { not: ProjectStatus.hidden },
          },
          select: {
            id: true,
            name: true,
            updates: {
              where: {
                status: { not: UpdateStatus.hidden },
                createdAt: { gte: since },
              },
              select: {
                id: true,
                urgency: true,
                createdAt: true,
              },
            },
          },
        }),
        this.prisma.communityPost.findMany({
          where: {
            status: ContentModerationStatus.active,
            createdAt: { gte: since },
          },
          orderBy: { createdAt: 'desc' },
          take: 30,
          include: {
            author: {
              select: {
                id: true,
                email: true,
                displayName: true,
                avatarUrl: true,
              },
            },
            _count: {
              select: {
                comments: true,
                reactions: true,
              },
            },
          },
        }),
      ]);

    const activeProjects = activeProjectRows
      .map((project) => {
        const updates = project.updates;
        const highCount = updates.filter(
          (update) => update.urgency === UpdateUrgency.high,
        ).length;
        const lastUpdateAt = updates
          .map((update) => update.createdAt)
          .sort((a, b) => b.getTime() - a.getTime())[0];

        return {
          projectId: project.id,
          projectName: project.name,
          newCount: updates.length,
          highCount,
          lastUpdateAt: lastUpdateAt ?? null,
        };
      })
      .filter((project) => project.newCount > 0)
      .sort((a, b) => {
        const byNewCount = b.newCount - a.newCount;
        if (byNewCount !== 0) return byNewCount;
        return b.highCount - a.highCount;
      })
      .slice(0, 8);

    const topCommunityPosts = communityRows
      .map((post) => ({
        id: post.id,
        topic: post.topic,
        contentPreview:
          post.content.length > 160
            ? `${post.content.slice(0, 160)}...`
            : post.content,
        likesCount: post._count.reactions,
        commentsCount: post._count.comments,
        createdAt: post.createdAt,
        author: {
          id: post.author.id,
          name: post.author.displayName ?? post.author.email ?? 'User',
          imageUrl: post.author.avatarUrl ?? '',
        },
      }))
      .sort((a, b) => {
        const scoreA = a.likesCount * 2 + a.commentsCount * 3;
        const scoreB = b.likesCount * 2 + b.commentsCount * 3;
        if (scoreB !== scoreA) return scoreB - scoreA;
        return b.createdAt.getTime() - a.createdAt.getTime();
      })
      .slice(0, 5);

    if (!options?.skipAudit) {
      await this.logDigestViewAuditIfDue(userId, {
        windowDays: boundedWindow,
      });
    }

    return {
      windowDays: boundedWindow,
      missedHighUrgency: missedHighUrgencyRows.map((row) => ({
        updateId: row.id,
        title: row.title,
        urgency: row.urgency,
        createdAt: row.createdAt,
        projectId: row.projectId,
        projectName: row.project.name,
      })),
      activeProjects,
      topCommunityPosts,
    };
  }

  private async logDigestViewAuditIfDue(
    userId: string,
    metadata: Record<string, unknown>,
  ) {
    const lastDigestView = await this.prisma.auditLog.findFirst({
      where: {
        actorId: userId,
        action: 'digest.view',
        resourceType: 'digest',
      },
      orderBy: {
        createdAt: 'desc',
      },
      select: {
        createdAt: true,
      },
    });

    if (lastDigestView) {
      const elapsedMs = Date.now() - lastDigestView.createdAt.getTime();
      if (elapsedMs < DIGEST_VIEW_AUDIT_COOLDOWN_MS) {
        return;
      }
    }

    await this.auditLogService.create({
      actorId: userId,
      action: 'digest.view',
      resourceType: 'digest',
      metadata,
    });
  }
}
