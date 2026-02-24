import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  MiningConfig,
  MiningPointSource,
  Prisma,
  TipAccountType,
} from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { BadgesService } from '../badges/badges.service';
import { PrismaService } from '../prisma/prisma.service';
import { QuestsService } from '../quests/quests.service';
import { MCR_CURRENCY_CODE } from '../tips/tip.constants';

const MCR_ATOMIC_MULTIPLIER = 1000n;

type MiningSessionStatus = 'idle' | 'running' | 'claimable';

type EffectiveMiningConfig = {
  enabled: boolean;
  referralsEnabled: boolean;
  cycleHours: number;
  basePointsPerCycle: number;
  perActiveReferralBoostBps: number;
  maxBoostBps: number;
  activeReferralWindowHours: number;
  referralBindWindowHours: number;
};

type PrismaLike = PrismaService | Prisma.TransactionClient;

type GetLeaderboardOptions = {
  q?: string;
  limit?: number;
  offset?: number;
  includePrivateFields?: boolean;
};

type MiningSessionRow = {
  id: string;
  startsAt: Date;
  endsAt: Date;
  claimedAt: Date | null;
  basePointsPerCycle: number;
  effectivePointsPerCycle: number;
  boostBpsSnapshot: number;
  activeReferralsSnapshot: number;
};

const DEFAULT_MINING_CONFIG: EffectiveMiningConfig = {
  enabled: true,
  referralsEnabled: true,
  cycleHours: 24,
  basePointsPerCycle: 120,
  perActiveReferralBoostBps: 500,
  maxBoostBps: 10000,
  activeReferralWindowHours: 168,
  referralBindWindowHours: 24,
};

@Injectable()
export class MiningService {
  private readonly logger = new Logger(MiningService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly auditLogService: AuditLogService,
    private readonly badgesService: BadgesService,
    private readonly questsService: QuestsService,
  ) {}

  async getMe(userId: string) {
    const asOf = new Date();
    const config = await this.getEffectiveConfig();

    await this.syncHourlyAccrualForUser(userId, asOf, config);

    const [
      profile,
      latestUnclaimedSession,
      maturedUnclaimedAggregate,
      totalDirectReferrals,
      activeDirectReferrals,
      hourlyHistoryRows,
    ] = await Promise.all([
      this.prisma.profile.findUnique({
        where: { id: userId },
        select: {
          id: true,
          createdAt: true,
          referralCode: true,
          referredById: true,
          miningClaimedPoints: true,
        },
      }),
      this.prisma.miningSession.findFirst({
        where: {
          userId,
          claimedAt: null,
        },
        orderBy: {
          startsAt: 'desc',
        },
      }),
      this.prisma.miningHourlyCheckpoint.aggregate({
        where: {
          userId,
          claimedAt: null,
          hourEndAt: {
            lte: asOf,
          },
        },
        _sum: {
          points: true,
        },
      }),
      this.prisma.profile.count({
        where: {
          referredById: userId,
        },
      }),
      this.countActiveDirectReferrals(userId, config, asOf),
      this.prisma.miningHourlyCheckpoint.findMany({
        where: {
          userId,
        },
        orderBy: [{ hourEndAt: 'desc' }, { createdAt: 'desc' }],
        take: 48,
        select: {
          id: true,
          sessionId: true,
          hourIndex: true,
          hourStartAt: true,
          hourEndAt: true,
          points: true,
          activeReferralsSnapshot: true,
          boostBpsSnapshot: true,
          claimedAt: true,
        },
      }),
    ]);

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    const referrer = profile.referredById
      ? await this.prisma.profile.findUnique({
          where: { id: profile.referredById },
          select: {
            id: true,
            displayName: true,
            email: true,
            referralCode: true,
          },
        })
      : null;

    const claimedTotalPoints = this.bigIntToNumber(profile.miningClaimedPoints);
    const maturedUnclaimedPoints = maturedUnclaimedAggregate._sum.points ?? 0;

    const session = latestUnclaimedSession
      ? await this.toSessionState(
          userId,
          latestUnclaimedSession,
          asOf,
          config,
          activeDirectReferrals,
        )
      : {
          id: null,
          status: 'idle' as MiningSessionStatus,
          startsAt: null,
          endsAt: null,
          progressPct: 0,
          pointsMinedSoFar: 0,
          effectivePointsPerCycle: config.basePointsPerCycle,
          boostBpsSnapshot: 0,
          activeReferralsSnapshot: activeDirectReferrals,
          hourlyRateNow: Number(
            (config.basePointsPerCycle / Math.max(config.cycleHours, 1)).toFixed(
              4,
            ),
          ),
          currentHourEstimatedPoints: 0,
          completedHours: 0,
          cycleHours: config.cycleHours,
          projectedCyclePointsNow: config.basePointsPerCycle,
        };

    const canBindUntil = new Date(
      profile.createdAt.getTime() +
        config.referralBindWindowHours * 60 * 60 * 1000,
    );
    const bindWindowOpen = !profile.referredById && asOf <= canBindUntil;

    return {
      asOf,
      config,
      balance: {
        claimedTotalPoints,
        maturedUnclaimedPoints,
        lifetimeEarnedPoints: claimedTotalPoints + maturedUnclaimedPoints,
      },
      session,
      referral: {
        code: profile.referralCode,
        referredBy: referrer
          ? {
              id: referrer.id,
              displayName: referrer.displayName,
              email: referrer.email,
              code: referrer.referralCode,
            }
          : null,
        canBindUntil,
        bindWindowOpen,
        activeDirectReferrals,
        totalDirectReferrals,
      },
      hourlyHistory: hourlyHistoryRows.map((row) => ({
        id: row.id,
        sessionId: row.sessionId,
        hourIndex: row.hourIndex,
        hourStartAt: row.hourStartAt,
        hourEndAt: row.hourEndAt,
        points: row.points,
        activeReferralsSnapshot: row.activeReferralsSnapshot,
        boostBpsSnapshot: row.boostBpsSnapshot,
        claimedAt: row.claimedAt,
        status: row.claimedAt ? 'claimed' : 'unclaimed',
      })),
    };
  }

  async start(userId: string) {
    const config = await this.getEffectiveConfig();
    if (!config.enabled) {
      throw new BadRequestException('Mining is disabled');
    }

    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    const asOf = new Date();

    await this.syncHourlyAccrualForUser(userId, asOf, config);

    const unclaimedSessions = await this.prisma.miningSession.findMany({
      where: {
        userId,
        claimedAt: null,
      },
      orderBy: {
        startsAt: 'desc',
      },
      take: 10,
    });

    const running = unclaimedSessions.find(
      (session) => session.endsAt.getTime() > asOf.getTime(),
    );

    if (running) {
      return {
        ok: true,
        status: 'running',
        session: await this.toSessionState(userId, running, asOf, config),
      };
    }

    const claimable = unclaimedSessions.find(
      (session) => session.endsAt.getTime() <= asOf.getTime(),
    );

    if (claimable) {
      throw new ConflictException({
        code: 'claim_required',
        message: 'Claim the previous mining cycle before starting a new one',
      });
    }

    const session = await this.createMiningSession(userId, asOf, config);

    await this.auditLogService.create({
      actorId: userId,
      action: 'mining.start',
      resourceType: 'mining_session',
      resourceId: session.id,
      metadata: {
        startsAt: session.startsAt.toISOString(),
        endsAt: session.endsAt.toISOString(),
        effectivePointsPerCycle: session.effectivePointsPerCycle,
        boostBpsSnapshot: session.boostBpsSnapshot,
        activeReferralsSnapshot: session.activeReferralsSnapshot,
      },
    });

    return {
      ok: true,
      status: 'started',
      session: await this.toSessionState(
        userId,
        session,
        asOf,
        config,
        session.activeReferralsSnapshot,
      ),
    };
  }

  async claim(userId: string) {
    const asOf = new Date();
    const config = await this.getEffectiveConfig();

    await this.syncHourlyAccrualForUser(userId, asOf, config);

    const unclaimedSessions = await this.prisma.miningSession.findMany({
      where: {
        userId,
        claimedAt: null,
      },
      orderBy: {
        startsAt: 'desc',
      },
      take: 10,
    });

    const claimable = unclaimedSessions.find(
      (session) => session.endsAt.getTime() <= asOf.getTime(),
    );

    if (!claimable) {
      throw new ConflictException({
        code: 'not_claimable',
        message: 'No completed mining cycle is available to claim',
      });
    }

    const [checkpointAggregate, checkpointCount] = await Promise.all([
      this.prisma.miningHourlyCheckpoint.aggregate({
        where: {
          sessionId: claimable.id,
          claimedAt: null,
        },
        _sum: {
          points: true,
        },
      }),
      this.prisma.miningHourlyCheckpoint.count({
        where: {
          sessionId: claimable.id,
          claimedAt: null,
        },
      }),
    ]);

    const checkpointPoints = checkpointAggregate._sum.points;
    const claimPoints =
      checkpointPoints != null && checkpointPoints > 0
        ? checkpointPoints
        : Math.max(claimable.effectivePointsPerCycle, 0);

    await this.prisma.$transaction(async (tx) => {
      const updated = await tx.miningSession.updateMany({
        where: {
          id: claimable.id,
          claimedAt: null,
        },
        data: {
          claimedAt: asOf,
        },
      });

      if (updated.count === 0) {
        throw new ConflictException({
          code: 'already_claimed',
          message: 'This mining session has already been claimed',
        });
      }

      await tx.miningHourlyCheckpoint.updateMany({
        where: {
          sessionId: claimable.id,
          claimedAt: null,
        },
        data: {
          claimedAt: asOf,
        },
      });

      await tx.miningPointLedger.create({
        data: {
          userId,
          sessionId: claimable.id,
          source: 'cycle_claim',
          points: claimPoints,
          metadata: {
            startsAt: claimable.startsAt.toISOString(),
            endsAt: claimable.endsAt.toISOString(),
            basePointsPerCycle: claimable.basePointsPerCycle,
            hourlyCheckpointCount: checkpointCount,
            boostBpsSnapshot: claimable.boostBpsSnapshot,
            activeReferralsSnapshot: claimable.activeReferralsSnapshot,
          },
        },
      });

      await tx.profile.update({
        where: { id: userId },
        data: {
          miningClaimedPoints: {
            increment: BigInt(claimPoints),
          },
        },
      });

      const tipCreditAtomic = BigInt(claimPoints) * MCR_ATOMIC_MULTIPLIER;
      if (tipCreditAtomic > 0n) {
        await tx.tipCurrency.upsert({
          where: { code: MCR_CURRENCY_CODE },
          update: {},
          create: {
            code: MCR_CURRENCY_CODE,
            name: 'Mine Credits',
            symbol: 'MCR',
            decimals: 3,
            kind: 'points',
            isEnabled: true,
            isActiveTippingCurrency: true,
          },
        });

        await tx.tipAccount.upsert({
          where: {
            accountType_ownerRef_currencyCode: {
              accountType: TipAccountType.user,
              ownerRef: userId,
              currencyCode: MCR_CURRENCY_CODE,
            },
          },
          update: {
            userId,
            balanceAtomic: {
              increment: tipCreditAtomic,
            },
          },
          create: {
            accountType: TipAccountType.user,
            ownerRef: userId,
            userId,
            currencyCode: MCR_CURRENCY_CODE,
            balanceAtomic: tipCreditAtomic,
          },
        });
      }
    });

    await this.auditLogService.create({
      actorId: userId,
      action: 'mining.claim',
      resourceType: 'mining_session',
      resourceId: claimable.id,
      metadata: {
        claimedAt: asOf.toISOString(),
        points: claimPoints,
        hourlyCheckpointCount: checkpointCount,
      },
    });

    let nextSessionState: Awaited<ReturnType<typeof this.toSessionState>> | null =
      null;

    if (config.enabled) {
      const nextSessionAsOf = new Date();
      const unclaimedAfterClaim = await this.prisma.miningSession.findMany({
        where: {
          userId,
          claimedAt: null,
        },
        orderBy: {
          startsAt: 'desc',
        },
        take: 10,
      });

      const runningAfterClaim = unclaimedAfterClaim.find(
        (session) => session.endsAt.getTime() > nextSessionAsOf.getTime(),
      );
      const claimableAfterClaim = unclaimedAfterClaim.find(
        (session) => session.endsAt.getTime() <= nextSessionAsOf.getTime(),
      );

      if (runningAfterClaim) {
        nextSessionState = await this.toSessionState(
          userId,
          runningAfterClaim,
          nextSessionAsOf,
          config,
        );
      } else if (!claimableAfterClaim) {
        const nextSession = await this.createMiningSession(
          userId,
          nextSessionAsOf,
          config,
        );

        await this.auditLogService.create({
          actorId: userId,
          action: 'mining.start',
          resourceType: 'mining_session',
          resourceId: nextSession.id,
          metadata: {
            startsAt: nextSession.startsAt.toISOString(),
            endsAt: nextSession.endsAt.toISOString(),
            effectivePointsPerCycle: nextSession.effectivePointsPerCycle,
            boostBpsSnapshot: nextSession.boostBpsSnapshot,
            activeReferralsSnapshot: nextSession.activeReferralsSnapshot,
            trigger: 'auto_after_claim',
          },
        });

        nextSessionState = await this.toSessionState(
          userId,
          nextSession,
          nextSessionAsOf,
          config,
          nextSession.activeReferralsSnapshot,
        );
      }
    }

    const [profile, maturedUnclaimedAggregate] = await Promise.all([
      this.prisma.profile.findUnique({
        where: { id: userId },
        select: { miningClaimedPoints: true },
      }),
      this.prisma.miningHourlyCheckpoint.aggregate({
        where: {
          userId,
          claimedAt: null,
          hourEndAt: {
            lte: asOf,
          },
        },
        _sum: {
          points: true,
        },
      }),
    ]);

    const claimedTotalPoints = this.bigIntToNumber(
      profile?.miningClaimedPoints ?? 0n,
    );
    const maturedUnclaimedPoints = maturedUnclaimedAggregate._sum.points ?? 0;

    // Check and award mining milestone badges
    await this.badgesService.checkMiningMilestones(userId, claimedTotalPoints);
    await this.triggerSevenDayStreakQuestIfEligible(userId);

    return {
      ok: true,
      sessionId: claimable.id,
      claimedAt: asOf,
      claimedPoints: claimPoints,
      balance: {
        claimedTotalPoints,
        maturedUnclaimedPoints,
        lifetimeEarnedPoints: claimedTotalPoints + maturedUnclaimedPoints,
      },
      nextSession: nextSessionState,
    };
  }

  async getAdminConfig() {
    return this.getEffectiveConfig();
  }

  async updateAdminConfig(
    actorId: string,
    patch: Partial<EffectiveMiningConfig>,
  ) {
    const row = await this.prisma.miningConfig.upsert({
      where: { id: 'default' },
      update: patch,
      create: {
        id: 'default',
        ...DEFAULT_MINING_CONFIG,
        ...patch,
      },
    });

    const config = this.withEnvFlagOverrides(row);

    await this.auditLogService.create({
      actorId,
      action: 'admin.mining.config.update',
      resourceType: 'mining_config',
      resourceId: row.id,
      metadata: patch,
    });

    return config;
  }

  async getAdminMetrics() {
    const asOf = new Date();
    const since24h = new Date(asOf.getTime() - 24 * 60 * 60 * 1000);
    const config = await this.getEffectiveConfig();

    const [
      dauMinersRows,
      startsDay,
      claimsDay,
      avgBoost,
      totalProfiles,
      totalBoundProfiles,
      activeDirectReferrals,
    ] = await Promise.all([
      this.prisma.miningSession.findMany({
        where: {
          startsAt: {
            gte: since24h,
          },
        },
        select: {
          userId: true,
        },
        distinct: ['userId'],
      }),
      this.prisma.miningSession.count({
        where: {
          startsAt: {
            gte: since24h,
          },
        },
      }),
      this.prisma.miningSession.count({
        where: {
          claimedAt: {
            gte: since24h,
          },
        },
      }),
      this.prisma.miningSession.aggregate({
        where: {
          startsAt: {
            gte: since24h,
          },
        },
        _avg: {
          boostBpsSnapshot: true,
        },
      }),
      this.prisma.profile.count(),
      this.prisma.profile.count({
        where: {
          referredById: {
            not: null,
          },
        },
      }),
      this.countActiveReferralEdges(config, asOf),
    ]);

    const totalDirectReferrals = totalBoundProfiles;
    const referralBindRate =
      totalProfiles === 0
        ? 0
        : Number((totalBoundProfiles / totalProfiles).toFixed(4));
    const activeReferralRatio =
      totalDirectReferrals === 0
        ? 0
        : Number((activeDirectReferrals / totalDirectReferrals).toFixed(4));

    return {
      asOf,
      dauMiners: dauMinersRows.length,
      startsDay,
      claimsDay,
      averageBoostBps:
        avgBoost._avg.boostBpsSnapshot == null
          ? 0
          : Math.round(avgBoost._avg.boostBpsSnapshot),
      referralBindRate,
      activeReferralRatio,
      totalDirectReferrals,
      activeDirectReferrals,
    };
  }

  async getLeaderboard(options: GetLeaderboardOptions = {}) {
    const asOf = new Date();
    const limit = Math.min(Math.max(options.limit ?? 20, 1), 100);
    const offset = Math.max(options.offset ?? 0, 0);
    const searchQuery = options.q?.trim();

    const searchFilters: Prisma.ProfileWhereInput[] = [];
    if (searchQuery && searchQuery.length > 0) {
      searchFilters.push(
        {
          displayName: {
            contains: searchQuery,
            mode: 'insensitive',
          },
        },
        {
          username: {
            contains: searchQuery,
            mode: 'insensitive',
          },
        },
      );

      if (options.includePrivateFields) {
        searchFilters.push({
          email: {
            contains: searchQuery,
            mode: 'insensitive',
          },
        });
      }

      if (searchQuery.length >= 8) {
        searchFilters.push({
          id: searchQuery,
        });
      }
    }

    const leaderboardWhere: Prisma.ProfileWhereInput = {
      isDeactivated: false,
      AND: [
        {
          OR: [
            {
              miningClaimedPoints: {
                gt: BigInt(0),
              },
            },
            {
              miningSessions: {
                some: {},
              },
            },
          ],
        },
        ...(searchFilters.length > 0
          ? [
              {
                OR: searchFilters,
              } as Prisma.ProfileWhereInput,
            ]
          : []),
      ],
    };

    const [profiles, total] = await Promise.all([
      this.prisma.profile.findMany({
        where: leaderboardWhere,
        orderBy: [
          {
            miningClaimedPoints: 'desc',
          },
          {
            createdAt: 'asc',
          },
        ],
        skip: offset,
        take: limit,
        select: {
          id: true,
          email: true,
          username: true,
          displayName: true,
          avatarUrl: true,
          miningClaimedPoints: true,
          primaryBadge: {
            select: {
              id: true,
              slug: true,
              name: true,
              description: true,
              imageUrl: true,
              category: true,
              rarity: true,
            },
          },
          miningSessions: {
            where: {
              claimedAt: null,
            },
            orderBy: {
              startsAt: 'desc',
            },
            take: 1,
            select: {
              id: true,
              startsAt: true,
              endsAt: true,
              boostBpsSnapshot: true,
              activeReferralsSnapshot: true,
            },
          },
        },
      }),
      this.prisma.profile.count({
        where: leaderboardWhere,
      }),
    ]);

    if (profiles.length === 0) {
      return {
        asOf,
        total,
        limit,
        offset,
        data: [] as Array<Record<string, unknown>>,
      };
    }

    const userIds = profiles.map((profile) => profile.id);
    const maturedUnclaimedRows = await this.prisma.miningHourlyCheckpoint.groupBy({
      by: ['userId'],
      where: {
        userId: {
          in: userIds,
        },
        claimedAt: null,
        hourEndAt: {
          lte: asOf,
        },
      },
      _sum: {
        points: true,
      },
    });

    const maturedByUserId = new Map<string, number>(
      maturedUnclaimedRows.map((row) => [row.userId, row._sum.points ?? 0]),
    );

    return {
      asOf,
      total,
      limit,
      offset,
      data: profiles.map((profile, index) => {
        const currentSession = profile.miningSessions[0] ?? null;
        const claimedTotalPoints = this.bigIntToNumber(
          profile.miningClaimedPoints,
        );
        const maturedUnclaimedPoints = maturedByUserId.get(profile.id) ?? 0;
        const lifetimeEarnedPoints = claimedTotalPoints + maturedUnclaimedPoints;
        const sessionStatus: MiningSessionStatus = !currentSession
          ? 'idle'
          : currentSession.endsAt.getTime() <= asOf.getTime()
            ? 'claimable'
            : 'running';

        return {
          rank: offset + index + 1,
          userId: profile.id,
          email: options.includePrivateFields ? profile.email : undefined,
          username: profile.username,
          displayName: profile.displayName,
          avatarUrl: profile.avatarUrl,
          primaryBadge: profile.primaryBadge ?? null,
          claimedTotalPoints,
          maturedUnclaimedPoints,
          lifetimeEarnedPoints,
          sessionStatus,
          sessionProgressPct: currentSession
            ? this.computeProgressPct(
                currentSession.startsAt,
                currentSession.endsAt,
                asOf,
              )
            : 0,
          sessionEndsAt: currentSession?.endsAt ?? null,
          boostBpsSnapshot: currentSession?.boostBpsSnapshot ?? 0,
          activeReferralsSnapshot: currentSession?.activeReferralsSnapshot ?? 0,
        };
      }),
    };
  }

  private async getEffectiveConfig(): Promise<EffectiveMiningConfig> {
    const row = await this.getOrCreateConfig();
    return this.withEnvFlagOverrides(row);
  }

  private async getOrCreateConfig(): Promise<MiningConfig> {
    return this.prisma.miningConfig.upsert({
      where: { id: 'default' },
      update: {},
      create: {
        id: 'default',
        ...DEFAULT_MINING_CONFIG,
      },
    });
  }

  private withEnvFlagOverrides(config: MiningConfig): EffectiveMiningConfig {
    const miningEnabledFlag = this.configService.get<boolean>(
      'ENABLE_MINING',
      true,
    );
    const referralsEnabledFlag = this.configService.get<boolean>(
      'ENABLE_REFERRALS',
      true,
    );

    return {
      enabled: config.enabled && miningEnabledFlag,
      referralsEnabled:
        config.enabled &&
        config.referralsEnabled &&
        miningEnabledFlag &&
        referralsEnabledFlag,
      cycleHours: config.cycleHours,
      basePointsPerCycle: config.basePointsPerCycle,
      perActiveReferralBoostBps: config.perActiveReferralBoostBps,
      maxBoostBps: config.maxBoostBps,
      activeReferralWindowHours: config.activeReferralWindowHours,
      referralBindWindowHours: config.referralBindWindowHours,
    };
  }

  private async syncHourlyAccrualForUser(
    userId: string,
    asOf: Date,
    config: EffectiveMiningConfig,
    prisma: PrismaLike = this.prisma,
  ) {
    const sessions = await prisma.miningSession.findMany({
      where: {
        userId,
        claimedAt: null,
      },
      orderBy: {
        startsAt: 'asc',
      },
    });

    for (const session of sessions) {
      await this.syncHourlyAccrualForSession(session, asOf, config, prisma);
    }
  }

  private async syncHourlyAccrualForSession(
    session: {
      id: string;
      userId: string;
      startsAt: Date;
      endsAt: Date;
      basePointsPerCycle: number;
    },
    asOf: Date,
    config: EffectiveMiningConfig,
    prisma: PrismaLike,
  ) {
    const sessionCycleHours = this.computeSessionCycleHours(
      session.startsAt,
      session.endsAt,
    );
    const maturedHours = this.computeMaturedHours(
      session.startsAt,
      session.endsAt,
      asOf,
      sessionCycleHours,
    );

    if (maturedHours <= 0) {
      return;
    }

    const existingRows = await prisma.miningHourlyCheckpoint.findMany({
      where: {
        sessionId: session.id,
      },
      select: {
        hourIndex: true,
      },
    });
    const existingHourIndexes = new Set(existingRows.map((row) => row.hourIndex));

    for (let hourIndex = 1; hourIndex <= maturedHours; hourIndex++) {
      if (existingHourIndexes.has(hourIndex)) {
        continue;
      }

      const hourStartAt = new Date(
        session.startsAt.getTime() + (hourIndex - 1) * 60 * 60 * 1000,
      );
      const expectedHourEnd = new Date(hourStartAt.getTime() + 60 * 60 * 1000);
      const hourEndAt =
        expectedHourEnd.getTime() > session.endsAt.getTime()
          ? session.endsAt
          : expectedHourEnd;

      const activeReferralsSnapshot = await this.countActiveDirectReferralsAt(
        session.userId,
        config,
        hourEndAt,
        prisma,
      );

      const boostBpsSnapshot = this.computeBoostBps(
        activeReferralsSnapshot,
        config,
      );

      const points = this.computeHourlyCheckpointPoints(
        session.basePointsPerCycle,
        sessionCycleHours,
        boostBpsSnapshot,
      );

      await prisma.miningHourlyCheckpoint.create({
        data: {
          userId: session.userId,
          sessionId: session.id,
          hourIndex,
          hourStartAt,
          hourEndAt,
          activeReferralsSnapshot,
          boostBpsSnapshot,
          points,
        },
      });
    }
  }

  private async toSessionState(
    userId: string,
    session: MiningSessionRow,
    asOf: Date,
    config: EffectiveMiningConfig,
    activeDirectReferralsNow?: number,
  ) {
    const status: MiningSessionStatus =
      session.endsAt.getTime() <= asOf.getTime() ? 'claimable' : 'running';

    const sessionCycleHours = this.computeSessionCycleHours(
      session.startsAt,
      session.endsAt,
    );

    const accruedAggregate = await this.prisma.miningHourlyCheckpoint.aggregate({
      where: {
        sessionId: session.id,
        claimedAt: null,
        hourEndAt: {
          lte: asOf,
        },
      },
      _sum: {
        points: true,
      },
      _max: {
        hourIndex: true,
      },
    });

    const completedHours = accruedAggregate._max.hourIndex ?? 0;
    const pointsMinedSoFar = accruedAggregate._sum.points ?? 0;

    const activeReferrals =
      activeDirectReferralsNow ??
      (await this.countActiveDirectReferrals(userId, config, asOf));

    const liveBoostBps = this.computeBoostBps(activeReferrals, config);
    const projectedCyclePointsNow = this.computeProjectedCyclePoints(
      session.basePointsPerCycle,
      liveBoostBps,
    );
    const hourlyRateNow = projectedCyclePointsNow / sessionCycleHours;

    const elapsedHours = this.computeElapsedHours(
      session.startsAt,
      session.endsAt,
      asOf,
    );
    const wholeHours = mathFloor(elapsedHours);
    const currentHourFraction = status === 'running' ? elapsedHours - wholeHours : 0;
    const currentHourEstimatedPoints = Number(
      (hourlyRateNow * currentHourFraction).toFixed(4),
    );

    return {
      id: session.id,
      status,
      startsAt: session.startsAt,
      endsAt: session.endsAt,
      progressPct: this.computeProgressPct(session.startsAt, session.endsAt, asOf),
      pointsMinedSoFar,
      effectivePointsPerCycle: projectedCyclePointsNow,
      boostBpsSnapshot: liveBoostBps,
      activeReferralsSnapshot: activeReferrals,
      hourlyRateNow: Number(hourlyRateNow.toFixed(4)),
      currentHourEstimatedPoints,
      completedHours,
      cycleHours: sessionCycleHours,
      projectedCyclePointsNow,
    };
  }

  private computeSessionCycleHours(startsAt: Date, endsAt: Date): number {
    const durationMs = endsAt.getTime() - startsAt.getTime();
    if (durationMs <= 0) return 1;

    return Math.max(1, Math.round(durationMs / (60 * 60 * 1000)));
  }

  private computeMaturedHours(
    startsAt: Date,
    endsAt: Date,
    asOf: Date,
    cycleHours: number,
  ): number {
    const cappedEndMs = Math.min(asOf.getTime(), endsAt.getTime());
    const elapsedMs = cappedEndMs - startsAt.getTime();
    if (elapsedMs <= 0) return 0;

    return Math.min(cycleHours, Math.floor(elapsedMs / (60 * 60 * 1000)));
  }

  private computeElapsedHours(startsAt: Date, endsAt: Date, asOf: Date): number {
    const cappedEndMs = Math.min(asOf.getTime(), endsAt.getTime());
    const elapsedMs = cappedEndMs - startsAt.getTime();
    if (elapsedMs <= 0) {
      return 0;
    }

    const cycleHours = this.computeSessionCycleHours(startsAt, endsAt);
    return Math.min(cycleHours, elapsedMs / (60 * 60 * 1000));
  }

  private computeProgressPct(startsAt: Date, endsAt: Date, asOf: Date): number {
    const durationMs = endsAt.getTime() - startsAt.getTime();
    if (durationMs <= 0) return 1;

    const elapsedMs = asOf.getTime() - startsAt.getTime();
    if (elapsedMs <= 0) return 0;
    if (elapsedMs >= durationMs) return 1;

    return elapsedMs / durationMs;
  }

  private computeBoostBps(
    activeReferrals: number,
    config: EffectiveMiningConfig,
  ): number {
    if (!config.referralsEnabled) {
      return 0;
    }

    return Math.min(
      activeReferrals * config.perActiveReferralBoostBps,
      config.maxBoostBps,
    );
  }

  private computeProjectedCyclePoints(
    basePointsPerCycle: number,
    boostBps: number,
  ): number {
    return Math.floor((basePointsPerCycle * (10000 + boostBps)) / 10000);
  }

  private computeHourlyCheckpointPoints(
    basePointsPerCycle: number,
    cycleHours: number,
    boostBps: number,
  ): number {
    const projectedCyclePoints = this.computeProjectedCyclePoints(
      basePointsPerCycle,
      boostBps,
    );

    if (projectedCyclePoints <= 0) {
      return 0;
    }

    return Math.floor(projectedCyclePoints / Math.max(cycleHours, 1));
  }

  private async createMiningSession(
    userId: string,
    startsAt: Date,
    config: EffectiveMiningConfig,
    prisma: PrismaLike = this.prisma,
  ): Promise<MiningSessionRow> {
    const activeReferralsSnapshot = await this.countActiveDirectReferralsAt(
      userId,
      config,
      startsAt,
      prisma,
    );
    const boostBpsSnapshot = this.computeBoostBps(
      activeReferralsSnapshot,
      config,
    );
    const effectivePointsPerCycle = this.computeProjectedCyclePoints(
      config.basePointsPerCycle,
      boostBpsSnapshot,
    );
    const endsAt = new Date(
      startsAt.getTime() + config.cycleHours * 60 * 60 * 1000,
    );

    return prisma.miningSession.create({
      data: {
        userId,
        startsAt,
        endsAt,
        basePointsPerCycle: config.basePointsPerCycle,
        activeReferralsSnapshot,
        boostBpsSnapshot,
        effectivePointsPerCycle,
      },
      select: {
        id: true,
        startsAt: true,
        endsAt: true,
        claimedAt: true,
        basePointsPerCycle: true,
        effectivePointsPerCycle: true,
        boostBpsSnapshot: true,
        activeReferralsSnapshot: true,
      },
    });
  }

  private async countActiveDirectReferrals(
    userId: string,
    config: EffectiveMiningConfig,
    asOf: Date,
  ): Promise<number> {
    return this.countActiveDirectReferralsAt(userId, config, asOf, this.prisma);
  }

  private async countActiveDirectReferralsAt(
    userId: string,
    config: EffectiveMiningConfig,
    asOf: Date,
    prisma: PrismaLike,
  ): Promise<number> {
    if (!config.referralsEnabled) {
      return 0;
    }

    const cutoff = new Date(
      asOf.getTime() - config.activeReferralWindowHours * 60 * 60 * 1000,
    );

    return prisma.profile.count({
      where: {
        referredById: userId,
        miningSessions: {
          some: {
            startsAt: {
              gte: cutoff,
              lte: asOf,
            },
          },
        },
      },
    });
  }

  private async countActiveReferralEdges(
    config: EffectiveMiningConfig,
    asOf: Date,
  ): Promise<number> {
    if (!config.referralsEnabled) {
      return 0;
    }

    const cutoff = new Date(
      asOf.getTime() - config.activeReferralWindowHours * 60 * 60 * 1000,
    );

    return this.prisma.profile.count({
      where: {
        referredById: {
          not: null,
        },
        miningSessions: {
          some: {
            startsAt: {
              gte: cutoff,
              lte: asOf,
            },
          },
        },
      },
    });
  }

  private async triggerSevenDayStreakQuestIfEligible(userId: string) {
    const streakDays = await this.getClaimStreakUtcDays(userId);
    if (streakDays < 7) {
      return;
    }

    try {
      await this.questsService.checkAndCompleteByAction(userId, '7_day_streak');
    } catch (error) {
      this.logger.warn(
        `Failed to process auto quest trigger`,
        JSON.stringify({
          action: '7_day_streak',
          userId,
          streakDays,
          error: error instanceof Error ? error.message : String(error),
        }),
      );
    }
  }

  private async getClaimStreakUtcDays(userId: string): Promise<number> {
    const rows = await this.prisma.miningPointLedger.findMany({
      where: {
        userId,
        source: MiningPointSource.cycle_claim,
      },
      orderBy: { createdAt: 'desc' },
      take: 30,
      select: { createdAt: true },
    });

    if (rows.length === 0) {
      return 0;
    }

    const uniqueDays: number[] = [];
    for (const row of rows) {
      const day = this.toUtcDayNumber(row.createdAt);
      if (uniqueDays.length === 0 || uniqueDays[uniqueDays.length - 1] !== day) {
        uniqueDays.push(day);
      }
    }

    if (uniqueDays.length === 0) {
      return 0;
    }

    let streak = 1;
    for (let i = 1; i < uniqueDays.length; i += 1) {
      if (uniqueDays[i - 1] - 1 === uniqueDays[i]) {
        streak += 1;
        continue;
      }
      break;
    }

    return streak;
  }

  private toUtcDayNumber(date: Date): number {
    const dayStartUtcMs = Date.UTC(
      date.getUTCFullYear(),
      date.getUTCMonth(),
      date.getUTCDate(),
    );
    return Math.floor(dayStartUtcMs / 86_400_000);
  }

  private bigIntToNumber(value: bigint | number): number {
    return typeof value === 'bigint' ? Number(value) : Number(value);
  }
}

function mathFloor(value: number): number {
  return Math.floor(value);
}
