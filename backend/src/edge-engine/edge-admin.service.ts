import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EdgeAction, Prisma, UpdateUrgency } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { EdgeFeedbackAction } from './dto/edge-feedback.dto';
import { GetAdminEdgeOverviewQuery } from './dto/get-admin-edge-overview.query';
import { RecomputeEdgeDecisionsDto } from './dto/recompute-edge-decisions.dto';
import { UpdateEdgeConfigDto } from './dto/update-edge-config.dto';
import { EdgeEngineService } from './edge-engine.service';
import {
  EDGE_CONFIG_ID,
  normalizeReasonCodes,
  roundScore,
  toFeedbackAction,
} from './edge-engine.utils';

type EdgeConfigRow = {
  id: string;
  enabled: boolean;
  mlEnabled: boolean;
  mlUrl: string;
  mlTimeout: number;
  mlProvider: string;
  mlWebSearch: boolean;
  mlOllamaModel: string;
  mlOllamaEmbeddingModel: string;
  mlOllamaTimeout: number;
  mlGroqModel: string;
  mlGeminiModel: string;
  mlGeminiEmbeddingModel: string;
  mlCacheTtl: number;
  mlMaxContentLength: number;
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
  mlQuality: number | null;
  mlSentiment: string | null;
  mlTopics: Prisma.JsonValue | null;
  mlActionability: number | null;
  mlInsights: Prisma.JsonValue | null;
  mlProvider: string | null;
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

function normalizeStringArray(value: Prisma.JsonValue | null) {
  if (!Array.isArray(value)) return [];
  return value
    .map((entry) => String(entry).trim())
    .filter((entry) => entry.length > 0);
}

@Injectable()
export class EdgeAdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly auditLogService: AuditLogService,
    private readonly edgeEngineService: EdgeEngineService,
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
        ...(patch.mlEnabled === undefined ? {} : { mlEnabled: patch.mlEnabled }),
        ...(patch.mlUrl === undefined ? {} : { mlUrl: patch.mlUrl }),
        ...(patch.mlTimeout === undefined ? {} : { mlTimeout: patch.mlTimeout }),
        ...(patch.mlProvider === undefined ? {} : { mlProvider: patch.mlProvider }),
        ...(patch.mlWebSearch === undefined ? {} : { mlWebSearch: patch.mlWebSearch }),
        ...(patch.mlOllamaModel === undefined ? {} : { mlOllamaModel: patch.mlOllamaModel }),
        ...(patch.mlOllamaEmbeddingModel === undefined
          ? {}
          : { mlOllamaEmbeddingModel: patch.mlOllamaEmbeddingModel }),
        ...(patch.mlOllamaTimeout === undefined ? {} : { mlOllamaTimeout: patch.mlOllamaTimeout }),
        ...(patch.mlGroqModel === undefined ? {} : { mlGroqModel: patch.mlGroqModel }),
        ...(patch.mlGeminiModel === undefined ? {} : { mlGeminiModel: patch.mlGeminiModel }),
        ...(patch.mlGeminiEmbeddingModel === undefined
          ? {}
          : { mlGeminiEmbeddingModel: patch.mlGeminiEmbeddingModel }),
        ...(patch.mlCacheTtl === undefined ? {} : { mlCacheTtl: patch.mlCacheTtl }),
        ...(patch.mlMaxContentLength === undefined
          ? {}
          : { mlMaxContentLength: patch.mlMaxContentLength }),
      },
      create: {
        id: EDGE_CONFIG_ID,
        enabled: patch.enabled ?? defaultEnabled,
      },
      select: {
        id: true,
        enabled: true,
        mlEnabled: true,
        mlUrl: true,
        mlTimeout: true,
        mlProvider: true,
        mlWebSearch: true,
        mlOllamaModel: true,
        mlOllamaEmbeddingModel: true,
        mlOllamaTimeout: true,
        mlGroqModel: true,
        mlGeminiModel: true,
        mlGeminiEmbeddingModel: true,
        mlCacheTtl: true,
        mlMaxContentLength: true,
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

  async recomputeDecisions(actorId: string, dto: RecomputeEdgeDecisionsDto) {
    const config = await this.getOrCreateConfig();
    const windowDays = Math.min(Math.max(dto.windowDays ?? 7, 1), 30);
    const userLimit = Math.min(Math.max(dto.userLimit ?? 5, 1), 50);

    if (!config.enabled) {
      throw new BadRequestException(
        'BEE runtime is disabled. Enable Edge Engine runtime first.',
      );
    }

    const targetUserIds = dto.userId
      ? [dto.userId]
      : (
          await this.prisma.projectFollow.findMany({
            select: {
              userId: true,
            },
            orderBy: {
              createdAt: 'desc',
            },
            distinct: ['userId'],
            take: userLimit,
          })
        ).map((row) => row.userId);

    if (targetUserIds.length === 0) {
      await this.auditLogService.create({
        actorId,
        action: 'edge.admin.recompute.run',
        resourceType: 'edge_recompute',
        metadata: {
          mlEnabled: config.mlEnabled,
          windowDays,
          userLimit,
          targetUsers: 0,
        },
      });

      return {
        ok: true,
        mlEnabled: config.mlEnabled,
        windowDays,
        requestedUsers: dto.userId ? 1 : userLimit,
        processedUsers: 0,
        successfulUsers: 0,
        failedUsers: 0,
        totalSignals: 0,
        details: [] as Array<{
          userId: string;
          ok: boolean;
          totalSignals: number;
          headline: string | null;
          error: string | null;
        }>,
        ranAt: new Date(),
      };
    }

    let successfulUsers = 0;
    let failedUsers = 0;
    let totalSignals = 0;
    const details: Array<{
      userId: string;
      ok: boolean;
      totalSignals: number;
      headline: string | null;
      error: string | null;
    }> = [];

    for (const userId of targetUserIds) {
      try {
        const brief = await this.edgeEngineService.getBrief(userId, {
          windowDays,
        });
        successfulUsers += 1;
        totalSignals += brief.totalSignals;
        details.push({
          userId,
          ok: true,
          totalSignals: brief.totalSignals,
          headline: brief.headline,
          error: null,
        });
      } catch (error) {
        failedUsers += 1;
        details.push({
          userId,
          ok: false,
          totalSignals: 0,
          headline: null,
          error: this.errorMessage(error),
        });
      }
    }

    await this.auditLogService.create({
      actorId,
      action: 'edge.admin.recompute.run',
      resourceType: 'edge_recompute',
      metadata: {
        mlEnabled: config.mlEnabled,
        windowDays,
        targetUsers: targetUserIds.length,
        successfulUsers,
        failedUsers,
        totalSignals,
      },
    });

    return {
      ok: true,
      mlEnabled: config.mlEnabled,
      windowDays,
      requestedUsers: dto.userId ? 1 : userLimit,
      processedUsers: targetUserIds.length,
      successfulUsers,
      failedUsers,
      totalSignals,
      details,
      ranAt: new Date(),
    };
  }

  async getAdminOverview(actorId: string, query: GetAdminEdgeOverviewQuery) {
    const asOf = new Date();
    const config = await this.getOrCreateConfig();
    const enabled = config.enabled;
    const mlEnabled = config.mlEnabled;
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
        ml: {
          enabled: mlEnabled,
          analyzedDecisions: 0,
          coverageRate: 0,
          avgQuality: 0,
          avgActionability: 0,
          sentiments: {
            positive: 0,
            neutral: 0,
            negative: 0,
            other: 0,
          },
          providers: [] as Array<{
            provider: string;
            count: number;
          }>,
          topTopics: [] as Array<{
            topic: string;
            count: number;
          }>,
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
          ml: {
            quality: number | null;
            sentiment: string | null;
            topics: string[];
            actionability: number | null;
            insights: string[];
            provider: string | null;
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
      mlAnalyzedDecisions,
      mlQualityAverage,
      mlActionabilityAverage,
      mlProviderGroups,
      mlSentimentGroups,
      mlTopicRows,
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
          mlQuality: true,
          mlSentiment: true,
          mlTopics: true,
          mlActionability: true,
          mlInsights: true,
          mlProvider: true,
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
      this.prisma.edgeDecision.count({
        where: {
          generatedAt: {
            gte: since,
          },
          OR: [
            { mlQuality: { not: null } },
            { mlSentiment: { not: null } },
            { mlTopics: { not: Prisma.DbNull } },
            { mlActionability: { not: null } },
            { mlInsights: { not: Prisma.DbNull } },
          ],
        },
      }),
      this.prisma.edgeDecision.aggregate({
        where: {
          generatedAt: {
            gte: since,
          },
        },
        _avg: {
          mlQuality: true,
        },
      }),
      this.prisma.edgeDecision.aggregate({
        where: {
          generatedAt: {
            gte: since,
          },
        },
        _avg: {
          mlActionability: true,
        },
      }),
      this.prisma.edgeDecision.groupBy({
        by: ['mlProvider'],
        where: {
          generatedAt: {
            gte: since,
          },
          mlProvider: {
            not: null,
          },
        },
        _count: {
          mlProvider: true,
        },
        orderBy: {
          _count: {
            mlProvider: 'desc',
          },
        },
        take: 6,
      }),
      this.prisma.edgeDecision.groupBy({
        by: ['mlSentiment'],
        where: {
          generatedAt: {
            gte: since,
          },
          mlSentiment: {
            not: null,
          },
        },
        _count: {
          mlSentiment: true,
        },
      }),
      this.prisma.edgeDecision.findMany({
        where: {
          generatedAt: {
            gte: since,
          },
          mlTopics: {
            not: Prisma.DbNull,
          },
        },
        orderBy: {
          generatedAt: 'desc',
        },
        take: 5000,
        select: {
          mlTopics: true,
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

    const topicCounts = new Map<string, number>();
    for (const row of mlTopicRows) {
      for (const topic of normalizeStringArray(row.mlTopics)) {
        const normalized = topic.toLowerCase();
        topicCounts.set(normalized, (topicCounts.get(normalized) ?? 0) + 1);
      }
    }
    const topTopics = Array.from(topicCounts.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 12)
      .map(([topic, count]) => ({
        topic,
        count,
      }));

    const sentimentSummary = {
      positive: 0,
      neutral: 0,
      negative: 0,
      other: 0,
    };
    for (const row of mlSentimentGroups) {
      const sentiment = row.mlSentiment?.trim().toLowerCase();
      const count = row._count?.mlSentiment ?? 0;
      if (sentiment === 'positive') {
        sentimentSummary.positive += count;
        continue;
      }
      if (sentiment === 'neutral') {
        sentimentSummary.neutral += count;
        continue;
      }
      if (sentiment === 'negative') {
        sentimentSummary.negative += count;
        continue;
      }
      sentimentSummary.other += count;
    }

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
      ml: {
        enabled: mlEnabled,
        analyzedDecisions: mlAnalyzedDecisions,
        coverageRate:
          decisionsCount > 0 ? roundScore(mlAnalyzedDecisions / decisionsCount) : 0,
        avgQuality: roundScore(mlQualityAverage._avg.mlQuality ?? 0),
        avgActionability: roundScore(
          mlActionabilityAverage._avg.mlActionability ?? 0,
        ),
        sentiments: sentimentSummary,
        providers: mlProviderGroups.map((row) => ({
          provider: row.mlProvider ?? 'unknown',
          count: row._count?.mlProvider ?? 0,
        })),
        topTopics,
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
        ml: {
          quality:
            row.mlQuality === null || row.mlQuality === undefined
              ? null
              : roundScore(row.mlQuality),
          sentiment: row.mlSentiment,
          topics: normalizeStringArray(row.mlTopics),
          actionability:
            row.mlActionability === null || row.mlActionability === undefined
              ? null
              : roundScore(row.mlActionability),
          insights: normalizeStringArray(row.mlInsights),
          provider: row.mlProvider,
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
        mlEnabled: false,
        mlUrl: 'http://localhost:8083',
        mlTimeout: 10000,
        mlProvider: 'auto',
        mlWebSearch: false,
        mlOllamaModel: 'llama3.3:70b',
        mlOllamaEmbeddingModel: 'nomic-embed-text',
        mlOllamaTimeout: 120000,
        mlGroqModel: 'llama-3.3-70b-versatile',
        mlGeminiModel: 'gemini-2.0-flash-exp',
        mlGeminiEmbeddingModel: 'models/text-embedding-004',
        mlCacheTtl: 86400,
        mlMaxContentLength: 10000,
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
        mlEnabled: true,
        mlUrl: true,
        mlTimeout: true,
        mlProvider: true,
        mlWebSearch: true,
        mlOllamaModel: true,
        mlOllamaEmbeddingModel: true,
        mlOllamaTimeout: true,
        mlGroqModel: true,
        mlGeminiModel: true,
        mlGeminiEmbeddingModel: true,
        mlCacheTtl: true,
        mlMaxContentLength: true,
        updatedAt: true,
      },
    })) as EdgeConfigRow;

    return row;
  }

  private errorMessage(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }
    return String(error);
  }
}
