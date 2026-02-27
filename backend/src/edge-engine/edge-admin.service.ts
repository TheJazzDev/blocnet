import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EdgeAction, Prisma, UpdateUrgency } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { EdgeFeedbackAction } from './dto/edge-feedback.dto';
import { GetAdminEdgeOverviewQuery } from './dto/get-admin-edge-overview.query';
import { UpdateEdgeConfigDto } from './dto/update-edge-config.dto';
import {
  EDGE_CONFIG_ID,
  normalizeReasonCodes,
  roundScore,
  toFeedbackAction,
} from './edge-engine.utils';

type EdgeConfigRow = {
  id: string;
  enabled: boolean;
  updatedAt: Date;
};

type AdminTopDecisionRow = {
  decisionId: string;
  edgeScore: number;
  recommendedAction: EdgeAction;
  reasonCodes: Prisma.JsonValue | null;
  explanationPreview: string | null;
  urgencyScore: number;
  recencyScore: number;
  relevanceScore: number;
  noveltyScore: number;
  penaltyScore: number;
  generatedAt: Date;
  user: {
    id: string;
    email: string;
    displayName: string | null;
  };
  project: {
    id: string;
    name: string;
    slug: string;
  };
  update: {
    id: string;
    title: string;
    urgency: UpdateUrgency;
    createdAt: Date;
  };
};

@Injectable()
export class EdgeAdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async getAdminConfig(actorId: string) {
    const config = await this.getOrCreateConfig();

    await this.auditLogService.create({
      actorId,
      action: 'edge.admin.config.view',
      resourceType: 'edge_config',
      resourceId: config.id,
      metadata: {
        enabled: config.enabled,
      },
    });

    return config;
  }

  async updateAdminConfig(actorId: string, patch: UpdateEdgeConfigDto) {
    const edgeConfigModel = this.getEdgeConfigModel();
    if (!edgeConfigModel?.upsert) {
      throw new BadRequestException('Edge config persistence is unavailable');
    }

    const defaultEnabled = this.configService.get<boolean>('ENABLE_BEE', true);
    const row = (await edgeConfigModel.upsert({
      where: { id: EDGE_CONFIG_ID },
      update: {
        ...(patch.enabled === undefined ? {} : { enabled: patch.enabled }),
      },
      create: {
        id: EDGE_CONFIG_ID,
        enabled: patch.enabled ?? defaultEnabled,
      },
      select: {
        id: true,
        enabled: true,
        updatedAt: true,
      },
    })) as EdgeConfigRow;

    await this.auditLogService.create({
      actorId,
      action: 'edge.admin.config.update',
      resourceType: 'edge_config',
      resourceId: row.id,
      metadata: {
        enabled: row.enabled,
      },
    });

    return row;
  }

  async getAdminOverview(actorId: string, query: GetAdminEdgeOverviewQuery) {
    const asOf = new Date();
    const enabled = await this.getBeeEnabled();
    const windowDays = Math.min(Math.max(query.windowDays ?? 7, 1), 30);
    const decisionsLimit = Math.min(
      Math.max(query.decisionsLimit ?? 20, 5),
      100,
    );
    const projectsLimit = Math.min(Math.max(query.projectsLimit ?? 8, 3), 20);
    const reasonLimit = Math.min(Math.max(query.reasonLimit ?? 10, 3), 30);
    const since = new Date(asOf.getTime() - windowDays * 24 * 60 * 60 * 1000);

    if (!enabled) {
      return {
        asOf,
        enabled,
        windowDays,
        totals: {
          decisions: 0,
          uniqueUsers: 0,
          uniqueProjects: 0,
          avgEdgeScore: 0,
          recommendedActionCounts: {
            act: 0,
            watch: 0,
            ignore: 0,
          },
          highUrgencyDecisions: 0,
        },
        feedback: {
          total: 0,
          act: 0,
          watch: 0,
          ignore: 0,
          feedbackRate: 0,
          lastFeedbackAt: null as Date | null,
        },
        telemetry: {
          feedViews: 0,
          briefViews: 0,
          explainViews: 0,
          feedbackEvents: 0,
        },
        topProjects: [] as Array<{
          projectId: string;
          projectName: string;
          projectSlug: string;
          decisionCount: number;
          highUrgencyCount: number;
          avgEdgeScore: number;
          lastDecisionAt: Date | null;
        }>,
        topReasons: {
          sampledDecisions: 0,
          items: [] as Array<{
            reasonCode: string;
            count: number;
          }>,
        },
        topDecisions: [] as Array<{
          decisionId: string;
          edgeScore: number;
          recommendedAction: EdgeFeedbackAction;
          reasonCodes: string[];
          explanationPreview: string;
          generatedAt: Date;
          user: {
            id: string;
            email: string;
            displayName: string | null;
          };
          project: {
            id: string;
            name: string;
            slug: string;
          };
          update: {
            id: string;
            title: string;
            urgency: UpdateUrgency;
            createdAt: Date;
          };
          components: {
            urgency: number;
            recency: number;
            relevance: number;
            novelty: number;
            penalties: number;
          };
        }>,
      };
    }

    const [
      decisionsCount,
      decisionsAvg,
      uniqueUsersRows,
      uniqueProjectsRows,
      recommendedActCount,
      recommendedWatchCount,
      recommendedIgnoreCount,
      highUrgencyDecisions,
      topProjectGroups,
      topDecisionRows,
      reasonSampleRows,
      feedbackCount,
      feedbackActCount,
      feedbackWatchCount,
      feedbackIgnoreCount,
      lastFeedback,
      feedViews,
      briefViews,
      explainViews,
      feedbackEvents,
    ] = await Promise.all([
      this.prisma.edgeDecision.count({
        where: {
          generatedAt: {
            gte: since,
          },
        },
      }),
      this.prisma.edgeDecision.aggregate({
        where: {
          generatedAt: {
            gte: since,
          },
        },
        _avg: {
          edgeScore: true,
        },
      }),
      this.prisma.edgeDecision.findMany({
        where: {
          generatedAt: {
            gte: since,
          },
        },
        distinct: ['userId'],
        select: {
          userId: true,
        },
      }),
      this.prisma.edgeDecision.findMany({
        where: {
          generatedAt: {
            gte: since,
          },
        },
        distinct: ['projectId'],
        select: {
          projectId: true,
        },
      }),
      this.prisma.edgeDecision.count({
        where: {
          generatedAt: {
            gte: since,
          },
          recommendedAction: EdgeAction.act,
        },
      }),
      this.prisma.edgeDecision.count({
        where: {
          generatedAt: {
            gte: since,
          },
          recommendedAction: EdgeAction.watch,
        },
      }),
      this.prisma.edgeDecision.count({
        where: {
          generatedAt: {
            gte: since,
          },
          recommendedAction: EdgeAction.ignore,
        },
      }),
      this.prisma.edgeDecision.count({
        where: {
          generatedAt: {
            gte: since,
          },
          update: {
            urgency: UpdateUrgency.high,
          },
        },
      }),
      this.prisma.edgeDecision.groupBy({
        by: ['projectId'],
        where: {
          generatedAt: {
            gte: since,
          },
        },
        _count: {
          projectId: true,
        },
        _avg: {
          edgeScore: true,
        },
        _max: {
          generatedAt: true,
        },
        orderBy: {
          _count: {
            projectId: 'desc',
          },
        },
        take: projectsLimit,
      }),
      this.prisma.edgeDecision.findMany({
        where: {
          generatedAt: {
            gte: since,
          },
        },
        orderBy: [{ edgeScore: 'desc' }, { generatedAt: 'desc' }],
        take: decisionsLimit,
        select: {
          decisionId: true,
          edgeScore: true,
          recommendedAction: true,
          reasonCodes: true,
          explanationPreview: true,
          urgencyScore: true,
          recencyScore: true,
          relevanceScore: true,
          noveltyScore: true,
          penaltyScore: true,
          generatedAt: true,
          user: {
            select: {
              id: true,
              email: true,
              displayName: true,
            },
          },
          project: {
            select: {
              id: true,
              name: true,
              slug: true,
            },
          },
          update: {
            select: {
              id: true,
              title: true,
              urgency: true,
              createdAt: true,
            },
          },
        },
      }),
      this.prisma.edgeDecision.findMany({
        where: {
          generatedAt: {
            gte: since,
          },
        },
        orderBy: [{ generatedAt: 'desc' }],
        take: 5000,
        select: {
          reasonCodes: true,
        },
      }),
      this.prisma.edgeFeedback.count({
        where: {
          createdAt: {
            gte: since,
          },
        },
      }),
      this.prisma.edgeFeedback.count({
        where: {
          createdAt: {
            gte: since,
          },
          action: EdgeAction.act,
        },
      }),
      this.prisma.edgeFeedback.count({
        where: {
          createdAt: {
            gte: since,
          },
          action: EdgeAction.watch,
        },
      }),
      this.prisma.edgeFeedback.count({
        where: {
          createdAt: {
            gte: since,
          },
          action: EdgeAction.ignore,
        },
      }),
      this.prisma.edgeFeedback.findFirst({
        where: {
          createdAt: {
            gte: since,
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
        select: {
          createdAt: true,
        },
      }),
      this.prisma.auditLog.count({
        where: {
          action: 'edge.feed.view',
          createdAt: {
            gte: since,
          },
        },
      }),
      this.prisma.auditLog.count({
        where: {
          action: 'edge.brief.view',
          createdAt: {
            gte: since,
          },
        },
      }),
      this.prisma.auditLog.count({
        where: {
          action: 'edge.explain.view',
          createdAt: {
            gte: since,
          },
        },
      }),
      this.prisma.auditLog.count({
        where: {
          action: {
            startsWith: 'edge.feedback.',
          },
          createdAt: {
            gte: since,
          },
        },
      }),
    ]);

    const projectIds = topProjectGroups.map((row) => row.projectId);
    const [projects, topProjectUrgencyRows] = projectIds.length
      ? await Promise.all([
          this.prisma.project.findMany({
            where: {
              id: {
                in: projectIds,
              },
            },
            select: {
              id: true,
              name: true,
              slug: true,
            },
          }),
          this.prisma.edgeDecision.findMany({
            where: {
              generatedAt: {
                gte: since,
              },
              projectId: {
                in: projectIds,
              },
            },
            select: {
              projectId: true,
              update: {
                select: {
                  urgency: true,
                },
              },
            },
          }),
        ])
      : [[], []];

    const projectMap = new Map(
      projects.map((project) => [project.id, project]),
    );
    const highUrgencyByProject = new Map<string, number>();
    for (const row of topProjectUrgencyRows) {
      if (row.update.urgency !== UpdateUrgency.high) continue;
      highUrgencyByProject.set(
        row.projectId,
        (highUrgencyByProject.get(row.projectId) ?? 0) + 1,
      );
    }

    const reasonCounts = new Map<string, number>();
    for (const row of reasonSampleRows) {
      for (const reason of normalizeReasonCodes(row.reasonCodes)) {
        reasonCounts.set(reason, (reasonCounts.get(reason) ?? 0) + 1);
      }
    }

    const topReasons = Array.from(reasonCounts.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, reasonLimit)
      .map(([reasonCode, count]) => ({
        reasonCode,
        count,
      }));

    await this.auditLogService.create({
      actorId,
      action: 'edge.admin.overview.view',
      resourceType: 'edge_admin_overview',
      metadata: {
        windowDays,
        decisionsCount,
      },
    });

    return {
      asOf,
      enabled,
      windowDays,
      totals: {
        decisions: decisionsCount,
        uniqueUsers: uniqueUsersRows.length,
        uniqueProjects: uniqueProjectsRows.length,
        avgEdgeScore: roundScore(decisionsAvg._avg.edgeScore ?? 0),
        recommendedActionCounts: {
          act: recommendedActCount,
          watch: recommendedWatchCount,
          ignore: recommendedIgnoreCount,
        },
        highUrgencyDecisions,
      },
      feedback: {
        total: feedbackCount,
        act: feedbackActCount,
        watch: feedbackWatchCount,
        ignore: feedbackIgnoreCount,
        feedbackRate:
          decisionsCount > 0 ? roundScore(feedbackCount / decisionsCount) : 0,
        lastFeedbackAt: lastFeedback?.createdAt ?? null,
      },
      telemetry: {
        feedViews,
        briefViews,
        explainViews,
        feedbackEvents,
      },
      topProjects: topProjectGroups.map((row) => {
        const project = projectMap.get(row.projectId);
        return {
          projectId: row.projectId,
          projectName: project?.name ?? 'Unknown Project',
          projectSlug: project?.slug ?? '',
          decisionCount: row._count?.projectId ?? 0,
          highUrgencyCount: highUrgencyByProject.get(row.projectId) ?? 0,
          avgEdgeScore: roundScore(row._avg?.edgeScore ?? 0),
          lastDecisionAt: row._max?.generatedAt ?? null,
        };
      }),
      topReasons: {
        sampledDecisions: reasonSampleRows.length,
        items: topReasons,
      },
      topDecisions: (topDecisionRows as AdminTopDecisionRow[]).map((row) => ({
        decisionId: row.decisionId,
        edgeScore: roundScore(row.edgeScore),
        recommendedAction: toFeedbackAction(row.recommendedAction),
        reasonCodes: normalizeReasonCodes(row.reasonCodes),
        explanationPreview: row.explanationPreview ?? '',
        generatedAt: row.generatedAt,
        user: row.user,
        project: row.project,
        update: row.update,
        components: {
          urgency: roundScore(row.urgencyScore),
          recency: roundScore(row.recencyScore),
          relevance: roundScore(row.relevanceScore),
          novelty: roundScore(row.noveltyScore),
          penalties: roundScore(row.penaltyScore),
        },
      })),
    };
  }

  private getEdgeConfigModel() {
    return (
      this.prisma as unknown as {
        edgeConfig?: {
          upsert?: (input: unknown) => Promise<unknown>;
        };
      }
    ).edgeConfig;
  }

  private async getOrCreateConfig(): Promise<EdgeConfigRow> {
    const defaultEnabled = this.configService.get<boolean>('ENABLE_BEE', true);
    const edgeConfigModel = this.getEdgeConfigModel();

    if (!edgeConfigModel?.upsert) {
      return {
        id: EDGE_CONFIG_ID,
        enabled: defaultEnabled,
        updatedAt: new Date(),
      };
    }

    const row = (await edgeConfigModel.upsert({
      where: { id: EDGE_CONFIG_ID },
      update: {},
      create: {
        id: EDGE_CONFIG_ID,
        enabled: defaultEnabled,
      },
      select: {
        id: true,
        enabled: true,
        updatedAt: true,
      },
    })) as EdgeConfigRow;

    return row;
  }

  private async getBeeEnabled() {
    const config = await this.getOrCreateConfig();
    return config.enabled;
  }
}
