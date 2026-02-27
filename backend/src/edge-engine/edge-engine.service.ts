import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  EdgeAction,
  Prisma,
  ProjectStatus,
  UpdateStatus,
  UpdateUrgency,
} from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { EdgeFeedbackAction, EdgeFeedbackDto } from './dto/edge-feedback.dto';
import { GetEdgeBriefQuery } from './dto/get-edge-brief.query';
import { ListEdgeFeedQuery } from './dto/list-edge-feed.query';
import {
  EDGE_CONFIG_ID,
  EDGE_DECISION_PREFIX,
  EDGE_WEIGHTS,
  EdgeFeedCursor,
  FollowPreference,
  clamp01,
  normalizeReasonCodes,
  noveltyScore,
  parseDecisionId,
  parseEdgeFeedCursor,
  penaltyScore,
  recencyScore,
  relevanceScore,
  roundScore,
  toEdgeFeedCursor,
  toExplanationPreview,
  toFeedbackAction,
  toPrismaEdgeAction,
  toReasonCodes,
  toRecommendedAction,
  urgencyScore,
} from './edge-engine.utils';

type UpdateCandidateRow = {
  id: string;
  projectId: string;
  title: string;
  urgency: UpdateUrgency;
  createdAt: Date;
  project: {
    id: string;
    name: string;
    slug: string;
  };
  secondaryTags: Array<{
    secondaryTagId: string;
  }>;
};

type EdgeDecision = {
  decisionId: string;
  edgeScore: number;
  recommendedAction: EdgeFeedbackAction;
  reasonCodes: string[];
  explanationPreview: string;
  components: {
    urgency: number;
    recency: number;
    relevance: number;
    novelty: number;
    penalties: number;
  };
  update: {
    id: string;
    title: string;
    urgency: UpdateUrgency;
    createdAt: Date;
    projectId: string;
    projectName: string;
    projectSlug: string;
    secondaryTagIds: string[];
  };
};

type PersistedDecisionRow = {
  id: string;
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
  update: {
    id: string;
    title: string;
    urgency: UpdateUrgency;
    createdAt: Date;
    secondaryTags: Array<{
      secondaryTagId: string;
    }>;
  };
  project: {
    id: string;
    name: string;
    slug: string;
  };
};

type EdgeConfigRow = {
  id: string;
  enabled: boolean;
  updatedAt: Date;
};

@Injectable()
export class EdgeEngineService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async getFeed(userId: string, query: ListEdgeFeedQuery) {
    const asOf = new Date();
    const enabled = await this.getBeeEnabled();
    const limit = Math.min(Math.max(query.limit ?? 20, 1), 40);

    if (!enabled) {
      return {
        asOf,
        enabled,
        limit,
        nextCursor: null as string | null,
        items: [] as EdgeDecision[],
      };
    }

    const context = await this.getUserContext(userId);
    if (context.follows.length === 0) {
      return {
        asOf,
        enabled,
        limit,
        nextCursor: null as string | null,
        items: [] as EdgeDecision[],
      };
    }

    const followMap = new Map<string, FollowPreference>(
      context.follows.map((follow) => [follow.projectId, follow]),
    );

    const cursor = query.cursor ? parseEdgeFeedCursor(query.cursor) : null;
    if (query.cursor && !cursor) {
      throw new BadRequestException('Invalid edge feed cursor');
    }
    const take = limit;

    const updates = await this.prisma.update.findMany({
      where: {
        projectId: {
          in: context.follows.map((follow) => follow.projectId),
        },
        status: {
          not: UpdateStatus.hidden,
        },
        project: {
          status: {
            not: ProjectStatus.hidden,
          },
        },
        ...(cursor
          ? cursor.id
            ? {
                OR: [
                  {
                    createdAt: {
                      lt: cursor.createdAt,
                    },
                  },
                  {
                    createdAt: cursor.createdAt,
                    id: {
                      lt: cursor.id,
                    },
                  },
                ],
              }
            : {
                createdAt: {
                  lt: cursor.createdAt,
                },
              }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take,
      select: {
        id: true,
        projectId: true,
        title: true,
        urgency: true,
        createdAt: true,
        secondaryTags: {
          select: {
            secondaryTagId: true,
          },
        },
        project: {
          select: {
            id: true,
            name: true,
            slug: true,
          },
        },
      },
    });

    const decisions = updates
      .map((update) =>
        this.buildDecision(update, followMap.get(update.projectId), asOf),
      )
      .sort((a, b) => {
        const byScore = b.edgeScore - a.edgeScore;
        if (byScore !== 0) return byScore;
        return b.update.createdAt.getTime() - a.update.createdAt.getTime();
      });

    const items = decisions.slice(0, limit);
    const nextCursor =
      updates.length === limit
        ? toEdgeFeedCursor(
            updates[updates.length - 1].createdAt,
            updates[updates.length - 1].id,
          )
        : null;

    await this.persistDecisions(userId, items);

    await this.auditLogService.create({
      actorId: userId,
      action: 'edge.feed.view',
      resourceType: 'edge_feed',
      metadata: {
        limit,
        cursor: query.cursor ?? null,
        returned: items.length,
      },
    });

    return {
      asOf,
      enabled,
      limit,
      nextCursor,
      items,
    };
  }

  async getBrief(userId: string, query: GetEdgeBriefQuery) {
    const asOf = new Date();
    const enabled = await this.getBeeEnabled();
    const windowDays = Math.min(Math.max(query.windowDays ?? 7, 1), 30);

    if (!enabled) {
      return {
        asOf,
        enabled,
        windowDays,
        totalSignals: 0,
        highUrgencyCount: 0,
        recommendedNowCount: 0,
        watchCount: 0,
        topProjects: [] as Array<{
          projectId: string;
          projectName: string;
          count: number;
          highUrgencyCount: number;
          avgEdgeScore: number;
          lastUpdateAt: Date | null;
        }>,
        topDecisions: [] as Array<{
          decisionId: string;
          edgeScore: number;
          recommendedAction: EdgeFeedbackAction;
          title: string;
          projectName: string;
          urgency: UpdateUrgency;
          createdAt: Date;
        }>,
        headline: 'BEE is currently disabled.',
      };
    }

    const context = await this.getUserContext(userId);
    if (context.follows.length === 0) {
      return {
        asOf,
        enabled,
        windowDays,
        totalSignals: 0,
        highUrgencyCount: 0,
        recommendedNowCount: 0,
        watchCount: 0,
        topProjects: [],
        topDecisions: [],
        headline: 'Follow projects to receive an Edge brief.',
      };
    }

    const followMap = new Map<string, FollowPreference>(
      context.follows.map((follow) => [follow.projectId, follow]),
    );
    const since = new Date(asOf.getTime() - windowDays * 24 * 60 * 60 * 1000);

    const updates = await this.prisma.update.findMany({
      where: {
        projectId: {
          in: context.follows.map((follow) => follow.projectId),
        },
        status: {
          not: UpdateStatus.hidden,
        },
        project: {
          status: {
            not: ProjectStatus.hidden,
          },
        },
        createdAt: {
          gte: since,
        },
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: 250,
      select: {
        id: true,
        projectId: true,
        title: true,
        urgency: true,
        createdAt: true,
        secondaryTags: {
          select: {
            secondaryTagId: true,
          },
        },
        project: {
          select: {
            id: true,
            name: true,
            slug: true,
          },
        },
      },
    });

    const decisions = updates
      .map((update) =>
        this.buildDecision(update, followMap.get(update.projectId), asOf),
      )
      .sort((a, b) => b.edgeScore - a.edgeScore);

    await this.persistDecisions(userId, decisions);

    const highUrgencyCount = updates.filter(
      (update) => update.urgency === UpdateUrgency.high,
    ).length;
    const recommendedNowCount = decisions.filter(
      (decision) => decision.recommendedAction === EdgeFeedbackAction.act,
    ).length;
    const watchCount = decisions.filter(
      (decision) => decision.recommendedAction === EdgeFeedbackAction.watch,
    ).length;

    const projectMap = new Map<
      string,
      {
        projectId: string;
        projectName: string;
        count: number;
        highUrgencyCount: number;
        scoreTotal: number;
        lastUpdateAt: Date | null;
      }
    >();
    for (const decision of decisions) {
      const existing = projectMap.get(decision.update.projectId);
      if (!existing) {
        projectMap.set(decision.update.projectId, {
          projectId: decision.update.projectId,
          projectName: decision.update.projectName,
          count: 1,
          highUrgencyCount:
            decision.update.urgency === UpdateUrgency.high ? 1 : 0,
          scoreTotal: decision.edgeScore,
          lastUpdateAt: decision.update.createdAt,
        });
        continue;
      }

      existing.count += 1;
      existing.scoreTotal += decision.edgeScore;
      if (decision.update.urgency === UpdateUrgency.high) {
        existing.highUrgencyCount += 1;
      }
      if (
        !existing.lastUpdateAt ||
        decision.update.createdAt.getTime() > existing.lastUpdateAt.getTime()
      ) {
        existing.lastUpdateAt = decision.update.createdAt;
      }
    }

    const topProjects = Array.from(projectMap.values())
      .map((row) => ({
        projectId: row.projectId,
        projectName: row.projectName,
        count: row.count,
        highUrgencyCount: row.highUrgencyCount,
        avgEdgeScore: roundScore(row.scoreTotal / row.count),
        lastUpdateAt: row.lastUpdateAt,
      }))
      .sort((a, b) => {
        const byCount = b.count - a.count;
        if (byCount !== 0) return byCount;
        const byHigh = b.highUrgencyCount - a.highUrgencyCount;
        if (byHigh !== 0) return byHigh;
        return (
          (b.lastUpdateAt?.getTime() ?? 0) - (a.lastUpdateAt?.getTime() ?? 0)
        );
      })
      .slice(0, 6);

    const topDecisions = decisions.slice(0, 5).map((decision) => ({
      decisionId: decision.decisionId,
      edgeScore: decision.edgeScore,
      recommendedAction: decision.recommendedAction,
      title: decision.update.title,
      projectName: decision.update.projectName,
      urgency: decision.update.urgency,
      createdAt: decision.update.createdAt,
    }));

    await this.auditLogService.create({
      actorId: userId,
      action: 'edge.brief.view',
      resourceType: 'edge_brief',
      metadata: {
        windowDays,
        totalSignals: decisions.length,
      },
    });

    return {
      asOf,
      enabled,
      windowDays,
      totalSignals: decisions.length,
      highUrgencyCount,
      recommendedNowCount,
      watchCount,
      topProjects,
      topDecisions,
      headline: this.buildBriefHeadline(
        windowDays,
        recommendedNowCount,
        watchCount,
      ),
    };
  }

  async explain(userId: string, decisionId: string) {
    const asOf = new Date();
    const enabled = await this.getBeeEnabled();
    if (!enabled) {
      return {
        asOf,
        enabled,
        decisionId,
        message: 'BEE is currently disabled.',
      };
    }

    const persistedDecision = await this.findPersistedDecision(
      userId,
      decisionId,
    );
    const decision = persistedDecision
      ? this.toDecisionFromPersisted(persistedDecision)
      : await this.resolveAndPersistDecision(userId, decisionId, asOf);

    await this.auditLogService.create({
      actorId: userId,
      action: 'edge.explain.view',
      resourceType: 'edge_decision',
      resourceId: decision.decisionId,
      metadata: {
        score: decision.edgeScore,
      },
    });

    return {
      asOf,
      enabled,
      decisionId: decision.decisionId,
      update: decision.update,
      explanation: {
        edgeScore: decision.edgeScore,
        recommendedAction: decision.recommendedAction,
        reasonCodes: decision.reasonCodes,
        explanationPreview: decision.explanationPreview,
        weights: EDGE_WEIGHTS,
        components: decision.components,
        narrative: this.buildNarrative(decision),
      },
    };
  }

  async feedback(userId: string, dto: EdgeFeedbackDto) {
    const decisionId = dto.decisionId.trim();
    const enabled = await this.getBeeEnabled();
    if (!enabled) {
      return {
        ok: false,
        decisionId,
        action: dto.action,
        persisted: false,
        feedbackId: null as string | null,
        recordedAt: new Date(),
      };
    }

    const persisted = await this.ensureDecisionRecordForFeedback(
      userId,
      decisionId,
    );
    const feedback = await this.persistFeedback(
      userId,
      persisted?.id ?? null,
      dto,
    );

    await this.auditLogService.create({
      actorId: userId,
      action: `edge.feedback.${dto.action}`,
      resourceType: 'edge_decision',
      resourceId: decisionId,
      metadata: {
        context: dto.context ?? {},
      },
    });

    return {
      ok: true,
      decisionId,
      action: dto.action,
      persisted: Boolean(persisted),
      feedbackId: feedback?.id ?? null,
      recordedAt: new Date(),
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

  private async getUserContext(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        id: true,
        follows: {
          select: {
            projectId: true,
            alertMinUrgency: true,
          },
        },
      },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    return profile;
  }

  private buildDecision(
    update: UpdateCandidateRow,
    followPreference: FollowPreference | undefined,
    asOf: Date,
  ): EdgeDecision {
    const urgency = urgencyScore(update.urgency);
    const recency = recencyScore(update.createdAt, asOf);
    const relevance = relevanceScore(update.urgency, followPreference);
    const novelty = noveltyScore(update.createdAt, asOf);
    const penalties = penaltyScore(update.urgency, followPreference);

    const edgeScore = roundScore(
      clamp01(
        EDGE_WEIGHTS.urgency * urgency +
          EDGE_WEIGHTS.recency * recency +
          EDGE_WEIGHTS.relevance * relevance +
          EDGE_WEIGHTS.novelty * novelty -
          penalties,
      ),
    );
    const recommendedAction = toRecommendedAction(
      edgeScore,
      update.urgency,
      recency,
    );
    const reasonCodes = toReasonCodes(
      update.urgency,
      recency,
      followPreference,
      edgeScore,
      update.secondaryTags.length > 0,
    );

    return {
      decisionId: `${EDGE_DECISION_PREFIX}${update.id}`,
      edgeScore,
      recommendedAction,
      reasonCodes,
      explanationPreview: toExplanationPreview(recommendedAction),
      components: {
        urgency,
        recency,
        relevance,
        novelty,
        penalties: roundScore(penalties),
      },
      update: {
        id: update.id,
        title: update.title,
        urgency: update.urgency,
        createdAt: update.createdAt,
        projectId: update.projectId,
        projectName: update.project.name,
        projectSlug: update.project.slug,
        secondaryTagIds: update.secondaryTags.map((tag) => tag.secondaryTagId),
      },
    };
  }

  private buildBriefHeadline(
    windowDays: number,
    recommendedNowCount: number,
    watchCount: number,
  ) {
    if (recommendedNowCount > 0) {
      return `${recommendedNowCount} signal(s) need action in the next ${windowDays} day(s).`;
    }
    if (watchCount > 0) {
      return `${watchCount} signal(s) are worth watching in the next ${windowDays} day(s).`;
    }

    return 'No critical signals detected for this period.';
  }

  private buildNarrative(decision: EdgeDecision) {
    return `This decision is ranked at ${decision.edgeScore} because urgency is ${decision.update.urgency}, recency is ${decision.components.recency}, and relevance to your followed project is ${decision.components.relevance}.`;
  }

  private async persistDecisions(userId: string, decisions: EdgeDecision[]) {
    if (decisions.length === 0) return;

    const edgeDecisionModel = (
      this.prisma as unknown as {
        edgeDecision?: {
          upsert?: (input: unknown) => Promise<unknown>;
        };
      }
    ).edgeDecision;
    if (!edgeDecisionModel?.upsert) {
      return;
    }

    const generatedAt = new Date();
    await Promise.all(
      decisions.map((decision) =>
        edgeDecisionModel.upsert?.({
          where: {
            userId_decisionId: {
              userId,
              decisionId: decision.decisionId,
            },
          },
          update: {
            updateId: decision.update.id,
            projectId: decision.update.projectId,
            edgeScore: decision.edgeScore,
            recommendedAction: toPrismaEdgeAction(decision.recommendedAction),
            reasonCodes: decision.reasonCodes as Prisma.InputJsonValue,
            explanationPreview: decision.explanationPreview,
            urgencyScore: decision.components.urgency,
            recencyScore: decision.components.recency,
            relevanceScore: decision.components.relevance,
            noveltyScore: decision.components.novelty,
            penaltyScore: decision.components.penalties,
            generatedAt,
          },
          create: {
            userId,
            decisionId: decision.decisionId,
            updateId: decision.update.id,
            projectId: decision.update.projectId,
            edgeScore: decision.edgeScore,
            recommendedAction: toPrismaEdgeAction(decision.recommendedAction),
            reasonCodes: decision.reasonCodes as Prisma.InputJsonValue,
            explanationPreview: decision.explanationPreview,
            urgencyScore: decision.components.urgency,
            recencyScore: decision.components.recency,
            relevanceScore: decision.components.relevance,
            noveltyScore: decision.components.novelty,
            penaltyScore: decision.components.penalties,
            generatedAt,
          },
        }),
      ),
    );
  }

  private async findPersistedDecision(userId: string, decisionId: string) {
    const edgeDecisionModel = (
      this.prisma as unknown as {
        edgeDecision?: {
          findUnique?: (input: unknown) => Promise<unknown>;
        };
      }
    ).edgeDecision;
    if (!edgeDecisionModel?.findUnique) {
      return null;
    }

    const row = (await edgeDecisionModel.findUnique?.({
      where: {
        userId_decisionId: {
          userId,
          decisionId,
        },
      },
      include: {
        update: {
          select: {
            id: true,
            title: true,
            urgency: true,
            createdAt: true,
            secondaryTags: {
              select: {
                secondaryTagId: true,
              },
            },
          },
        },
        project: {
          select: {
            id: true,
            name: true,
            slug: true,
          },
        },
      },
    })) as PersistedDecisionRow | null;

    return row;
  }

  private toDecisionFromPersisted(row: PersistedDecisionRow): EdgeDecision {
    return {
      decisionId: row.decisionId,
      edgeScore: roundScore(row.edgeScore),
      recommendedAction: toFeedbackAction(row.recommendedAction),
      reasonCodes: normalizeReasonCodes(row.reasonCodes),
      explanationPreview: row.explanationPreview ?? '',
      components: {
        urgency: roundScore(row.urgencyScore),
        recency: roundScore(row.recencyScore),
        relevance: roundScore(row.relevanceScore),
        novelty: roundScore(row.noveltyScore),
        penalties: roundScore(row.penaltyScore),
      },
      update: {
        id: row.update.id,
        title: row.update.title,
        urgency: row.update.urgency,
        createdAt: row.update.createdAt,
        projectId: row.project.id,
        projectName: row.project.name,
        projectSlug: row.project.slug,
        secondaryTagIds: row.update.secondaryTags.map(
          (tag) => tag.secondaryTagId,
        ),
      },
    };
  }

  private async resolveAndPersistDecision(
    userId: string,
    decisionId: string,
    asOf: Date,
  ) {
    const updateId = parseDecisionId(decisionId);
    if (!updateId) {
      throw new NotFoundException('Edge decision not found');
    }

    const update = await this.prisma.update.findFirst({
      where: {
        id: updateId,
        status: {
          not: UpdateStatus.hidden,
        },
        project: {
          status: {
            not: ProjectStatus.hidden,
          },
        },
      },
      select: {
        id: true,
        projectId: true,
        title: true,
        urgency: true,
        createdAt: true,
        secondaryTags: {
          select: {
            secondaryTagId: true,
          },
        },
        project: {
          select: {
            id: true,
            name: true,
            slug: true,
          },
        },
      },
    });

    if (!update) {
      throw new NotFoundException('Edge decision not found');
    }

    const projectFollowModel = (
      this.prisma as unknown as {
        projectFollow?: {
          findUnique?: (input: unknown) => Promise<unknown>;
        };
      }
    ).projectFollow;
    const followPreference = projectFollowModel?.findUnique
      ? ((await projectFollowModel.findUnique({
          where: {
            projectId_userId: {
              projectId: update.projectId,
              userId,
            },
          },
          select: {
            projectId: true,
            alertMinUrgency: true,
          },
        })) as FollowPreference | null)
      : null;

    const decision = this.buildDecision(
      update,
      followPreference ?? undefined,
      asOf,
    );
    await this.persistDecisions(userId, [decision]);
    return decision;
  }

  private async ensureDecisionRecordForFeedback(
    userId: string,
    decisionId: string,
  ) {
    const edgeDecisionModel = (
      this.prisma as unknown as {
        edgeDecision?: {
          findUnique?: (input: unknown) => Promise<unknown>;
          upsert?: (input: unknown) => Promise<unknown>;
        };
      }
    ).edgeDecision;
    if (!edgeDecisionModel?.findUnique || !edgeDecisionModel?.upsert) {
      return null;
    }

    const existing = await this.findPersistedDecision(userId, decisionId);
    if (existing) {
      return existing;
    }

    await this.resolveAndPersistDecision(userId, decisionId, new Date());
    return this.findPersistedDecision(userId, decisionId);
  }

  private async persistFeedback(
    userId: string,
    decisionRecordId: string | null,
    dto: EdgeFeedbackDto,
  ) {
    if (!decisionRecordId) return null;

    const edgeFeedbackModel = (
      this.prisma as unknown as {
        edgeFeedback?: {
          create?: (input: unknown) => Promise<unknown>;
        };
      }
    ).edgeFeedback;
    if (!edgeFeedbackModel?.create) {
      return null;
    }

    const created = (await edgeFeedbackModel.create?.({
      data: {
        userId,
        decisionRecordId,
        decisionId: dto.decisionId.trim(),
        action: toPrismaEdgeAction(dto.action),
        context: (dto.context ?? {}) as Prisma.InputJsonValue,
      },
      select: {
        id: true,
      },
    })) as { id: string } | null;

    return created;
  }
}
