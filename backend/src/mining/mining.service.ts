import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { MiningPointSource, Prisma, TipAccountType } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { BadgesService } from '../badges/badges.service';
import { LevelsService } from '../levels/levels.service';
import { PrismaService } from '../prisma/prisma.service';
import { QuestsService } from '../quests/quests.service';
import { BNP_CURRENCY_CODE } from '../tips/tip.constants';
import {
  MiningCalculatorService,
  EffectiveMiningConfig,
} from './mining-calculator.service';
import { MiningConfigService } from './mining-config.service';

const BNP_ATOMIC_MULTIPLIER = 1000n;

type MiningSessionStatus = 'idle' | 'running' | 'claimable';

type PrismaLike = PrismaService | Prisma.TransactionClient;

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

@Injectable()
export class MiningService {
  private readonly logger = new Logger(MiningService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly badgesService: BadgesService,
    private readonly questsService: QuestsService,
    private readonly levelsService: LevelsService,
    private readonly miningCalculator: MiningCalculatorService,
    private readonly miningConfigService: MiningConfigService,
  ) {}

  async getMe(userId: string) {
    const asOf = new Date();
    const config = await this.miningConfigService.getEffectiveConfig();

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
            username: true,
            displayName: true,
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
            (
              config.basePointsPerCycle / Math.max(config.cycleHours, 1)
            ).toFixed(4),
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
              username: referrer.username,
              displayName: referrer.displayName,
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
    const config = await this.miningConfigService.getEffectiveConfig();
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
        session: await this.toSessionState(
          userId,
          running,
          asOf,
          config,
          running.activeReferralsSnapshot,
        ),
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

    const session = await this.createMiningSession(
      userId,
      config,
      asOf,
      this.prisma,
    );

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
    const config = await this.miningConfigService.getEffectiveConfig();

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

      const tipCreditAtomic = BigInt(claimPoints) * BNP_ATOMIC_MULTIPLIER;
      if (tipCreditAtomic > 0n) {
        await tx.tipCurrency.upsert({
          where: { code: BNP_CURRENCY_CODE },
          update: {},
          create: {
            code: BNP_CURRENCY_CODE,
            name: 'Blocnet Points',
            symbol: 'BNP',
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
              currencyCode: BNP_CURRENCY_CODE,
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
            currencyCode: BNP_CURRENCY_CODE,
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

    // Trigger level recalculation after BNP earned
    try {
      await this.levelsService.updateUserLevel(userId);
    } catch (error) {
      this.logger.warn(
        `Failed to update user level after mining claim: ${error instanceof Error ? error.message : String(error)}`,
      );
    }

    let nextSessionState: Awaited<
      ReturnType<typeof this.toSessionState>
    > | null = null;

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
          config,
          nextSessionAsOf,
          this.prisma,
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
    const sessionCycleHours = this.miningCalculator.computeSessionCycleHours(
      session.startsAt,
      session.endsAt,
    );
    const maturedHours = this.miningCalculator.computeMaturedHours(
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
    const existingHourIndexes = new Set(
      existingRows.map((row) => row.hourIndex),
    );

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

      const boostBpsSnapshot = this.miningCalculator.computeBoostBps(
        activeReferralsSnapshot,
        config,
      );

      const points = this.miningCalculator.computeHourlyCheckpointPoints(
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

    const sessionCycleHours = this.miningCalculator.computeSessionCycleHours(
      session.startsAt,
      session.endsAt,
    );

    const accruedAggregate = await this.prisma.miningHourlyCheckpoint.aggregate(
      {
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
      },
    );

    const pointsMinedSoFar = accruedAggregate._sum.points ?? 0;

    const activeReferrals =
      activeDirectReferralsNow ??
      (await this.countActiveDirectReferrals(userId, config, asOf));

    const liveBoostBps = this.miningCalculator.computeBoostBps(
      activeReferrals,
      config,
    );
    const projectedCyclePointsNow =
      this.miningCalculator.computeProjectedCyclePoints(
        session.basePointsPerCycle,
        liveBoostBps,
      );
    const hourlyRateNow = projectedCyclePointsNow / sessionCycleHours;

    const elapsedHours = this.miningCalculator.computeElapsedHours(
      session.startsAt,
      session.endsAt,
      asOf,
    );
    const wholeHours = mathFloor(elapsedHours);
    const currentHourFraction =
      status === 'running' ? elapsedHours - wholeHours : 0;
    const currentHourEstimatedPoints = Number(
      (hourlyRateNow * currentHourFraction).toFixed(4),
    );

    return {
      id: session.id,
      status,
      startsAt: session.startsAt,
      endsAt: session.endsAt,
      progressPct: this.miningCalculator.computeProgressPct(
        session.startsAt,
        session.endsAt,
        asOf,
      ),
      pointsMinedSoFar,
      effectivePointsPerCycle: projectedCyclePointsNow,
      boostBpsSnapshot: liveBoostBps,
      activeReferralsSnapshot: activeReferrals,
      hourlyRateNow: Number(hourlyRateNow.toFixed(4)),
      currentHourEstimatedPoints,
    };
  }

  private async createMiningSession(
    userId: string,
    config: EffectiveMiningConfig,
    now: Date,
    prisma: PrismaLike,
  ) {
    const startsAt = now;
    const endsAt = new Date(startsAt.getTime() + config.cycleHours * 3600000);

    const activeReferralsSnapshot = await this.countActiveDirectReferralsAt(
      userId,
      config,
      now,
      prisma,
    );
    const boostBpsSnapshot = this.miningCalculator.computeBoostBps(
      activeReferralsSnapshot,
      config,
    );
    const effectivePointsPerCycle =
      this.miningCalculator.computeProjectedCyclePoints(
        config.basePointsPerCycle,
        boostBpsSnapshot,
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
    referrerId: string,
    config: EffectiveMiningConfig,
    asOf: Date,
    prisma: PrismaLike,
  ) {
    if (!config.referralsEnabled) {
      return 0;
    }

    const windowStart = new Date(
      asOf.getTime() - config.activeReferralWindowHours * 3600000,
    );

    const count = await prisma.profile.count({
      where: {
        referredById: referrerId,
        homeFeedLastSeenAt: {
          gte: windowStart,
        },
      },
    });

    return count;
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
      if (
        uniqueDays.length === 0 ||
        uniqueDays[uniqueDays.length - 1] !== day
      ) {
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
