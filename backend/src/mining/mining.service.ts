import {
  BadRequestException,
  ConflictException,
  forwardRef,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { BadgesService } from '../badges/badges.service';
import { LevelsService } from '../levels/levels.service';
import { PrismaService } from '../prisma/prisma.service';
import { QuestsService } from '../quests/quests.service';
import {
  MiningCalculatorService,
  EffectiveMiningConfig,
} from './mining-calculator.service';
import { MiningConfigService } from './mining-config.service';
import {
  MiningExpiryService,
  type ForfeitedCycle,
} from './mining-expiry.service';
import {
  applyClaimSettlement,
  isClaimable,
  MiningSessionAlreadySettledError,
  resolveClaimPoints,
} from './mining-settlement';

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

/** An unsettled cycle is one that is neither paid out nor forfeited. */
const UNSETTLED = { claimedAt: null, expiredAt: null } as const;

function toExpiredCycleDto(cycle: ForfeitedCycle) {
  return {
    sessionId: cycle.sessionId,
    startsAt: cycle.startsAt,
    endsAt: cycle.endsAt,
    claimDeadline: cycle.claimDeadline,
    expiredAt: cycle.expiredAt,
    forfeitedPoints: cycle.forfeitedPoints,
  };
}

@Injectable()
export class MiningService {
  private readonly logger = new Logger(MiningService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly badgesService: BadgesService,
    @Inject(forwardRef(() => QuestsService))
    private readonly questsService: QuestsService,
    private readonly levelsService: LevelsService,
    private readonly miningCalculator: MiningCalculatorService,
    private readonly miningConfigService: MiningConfigService,
    private readonly miningExpiryService: MiningExpiryService,
  ) {}

  async getMe(userId: string) {
    const asOf = new Date();
    const config = await this.miningConfigService.getEffectiveConfig();

    await this.syncHourlyAccrualForUser(userId, asOf, config);
    // Reconcile on read: a cycle whose window elapsed is forfeited here, so the
    // snapshot never advertises points the user can no longer claim.
    await this.miningExpiryService.settleExpiredForUser(userId, asOf, config);

    const [
      profile,
      latestUnclaimedSession,
      maturedUnclaimedAggregate,
      totalDirectReferrals,
      activeDirectReferrals,
      hourlyHistoryRows,
      lastExpiredSession,
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
          ...UNSETTLED,
        },
        orderBy: {
          startsAt: 'desc',
        },
      }),
      this.prisma.miningHourlyCheckpoint.aggregate({
        where: {
          userId,
          ...UNSETTLED,
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
          expiredAt: true,
        },
      }),
      this.prisma.miningSession.findFirst({
        where: {
          userId,
          expiredAt: { not: null },
        },
        orderBy: {
          endsAt: 'desc',
        },
        select: {
          id: true,
          startsAt: true,
          endsAt: true,
          expiredAt: true,
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

    // Keep BigInt arithmetic in BigInt space and serialize to string at the
    // response boundary (never as a JS number) to avoid precision loss once
    // mining points scale past Number.MAX_SAFE_INTEGER.
    const claimedTotalPointsBigInt = profile.miningClaimedPoints;
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

    const lastExpiredCycle = lastExpiredSession
      ? {
          sessionId: lastExpiredSession.id,
          startsAt: lastExpiredSession.startsAt,
          endsAt: lastExpiredSession.endsAt,
          expiredAt: lastExpiredSession.expiredAt,
          forfeitedPoints:
            (
              await this.prisma.miningHourlyCheckpoint.aggregate({
                where: {
                  sessionId: lastExpiredSession.id,
                  expiredAt: { not: null },
                },
                _sum: { points: true },
              })
            )._sum.points ?? 0,
        }
      : null;

    const canBindUntil = new Date(
      profile.createdAt.getTime() +
        config.referralBindWindowHours * 60 * 60 * 1000,
    );
    const bindWindowOpen = !profile.referredById && asOf <= canBindUntil;

    return {
      asOf,
      config,
      balance: {
        claimedTotalPoints: claimedTotalPointsBigInt.toString(),
        maturedUnclaimedPoints,
        lifetimeEarnedPoints: (
          claimedTotalPointsBigInt + BigInt(maturedUnclaimedPoints)
        ).toString(),
      },
      session,
      /**
       * Most recent forfeited cycle, so clients can explain a missing payout
       * instead of showing a Claim button that can only fail. Null when the
       * account has never let a claim window elapse.
       */
      lastExpiredCycle,
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
        expiredAt: row.expiredAt,
        status: row.claimedAt
          ? 'claimed'
          : row.expiredAt
            ? 'expired'
            : 'unclaimed',
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
    // Reconcile on write: forfeit anything past its window first, so only a
    // genuinely claimable cycle can block a new one.
    const forfeited = await this.miningExpiryService.settleExpiredForUser(
      userId,
      asOf,
      config,
    );

    const unsettledSessions = await this.prisma.miningSession.findMany({
      where: {
        userId,
        ...UNSETTLED,
      },
      orderBy: {
        startsAt: 'desc',
      },
      take: 10,
    });

    const running = unsettledSessions.find(
      (session) => session.endsAt.getTime() > asOf.getTime(),
    );

    if (running) {
      return {
        ok: true,
        status: 'running',
        expiredCycles: forfeited.map(toExpiredCycleDto),
        session: await this.toSessionState(
          userId,
          running,
          asOf,
          config,
          running.activeReferralsSnapshot,
        ),
      };
    }

    const claimable = unsettledSessions.find((session) =>
      isClaimable(session, asOf, config),
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
      expiredCycles: forfeited.map(toExpiredCycleDto),
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
    // Reconcile on write: settle anything past its window before deciding what
    // is claimable, so claim() can never dead-end on a cycle it refuses to
    // settle (F-39).
    const forfeited = await this.miningExpiryService.settleExpiredForUser(
      userId,
      asOf,
      config,
    );

    const unsettledSessions = await this.prisma.miningSession.findMany({
      where: {
        userId,
        ...UNSETTLED,
      },
      orderBy: {
        startsAt: 'desc',
      },
      take: 10,
    });

    const claimable = unsettledSessions.find((session) =>
      isClaimable(session, asOf, config),
    );

    if (!claimable) {
      if (forfeited.length > 0) {
        return this.buildExpiredClaimResult(userId, asOf, config, forfeited);
      }

      throw new ConflictException({
        code: 'not_claimable',
        message: 'No completed mining cycle is available to claim',
      });
    }

    const [checkpointAggregate, checkpointCount] = await Promise.all([
      this.prisma.miningHourlyCheckpoint.aggregate({
        where: {
          sessionId: claimable.id,
          ...UNSETTLED,
        },
        _sum: {
          points: true,
        },
      }),
      this.prisma.miningHourlyCheckpoint.count({
        where: {
          sessionId: claimable.id,
          ...UNSETTLED,
        },
      }),
    ]);

    const claimPoints = resolveClaimPoints(
      checkpointAggregate._sum.points,
      claimable,
    );

    try {
      await this.prisma.$transaction((tx) =>
        applyClaimSettlement(tx, {
          userId,
          session: claimable,
          claimedAt: asOf,
          claimPoints,
          checkpointCount,
        }),
      );
    } catch (error) {
      if (error instanceof MiningSessionAlreadySettledError) {
        throw new ConflictException({
          code: 'already_claimed',
          message: 'This mining session has already been claimed',
        });
      }
      throw error;
    }

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

    const nextSessionState = await this.ensureNextSessionState(
      userId,
      config,
      'auto_after_claim',
    );

    const [profile, maturedUnclaimedAggregate] = await Promise.all([
      this.prisma.profile.findUnique({
        where: { id: userId },
        select: { miningClaimedPoints: true },
      }),
      this.prisma.miningHourlyCheckpoint.aggregate({
        where: {
          userId,
          ...UNSETTLED,
          hourEndAt: {
            lte: asOf,
          },
        },
        _sum: {
          points: true,
        },
      }),
    ]);

    const claimedTotalPointsBigInt = profile?.miningClaimedPoints ?? 0n;
    const maturedUnclaimedPoints = maturedUnclaimedAggregate._sum.points ?? 0;

    // Badge milestone thresholds are small Ints, so Number() is safe for
    // this specific comparison — but the response below still serializes
    // the real BigInt value as a string, per the documented pattern.
    await this.badgesService.checkMiningMilestones(
      userId,
      Number(claimedTotalPointsBigInt),
    );
    await this.triggerSevenDayStreakQuestIfEligible(userId);

    return {
      ok: true,
      status: 'claimed' as const,
      sessionId: claimable.id,
      claimedAt: asOf,
      claimedPoints: claimPoints,
      expiredCycles: forfeited.map(toExpiredCycleDto),
      balance: {
        claimedTotalPoints: claimedTotalPointsBigInt.toString(),
        maturedUnclaimedPoints,
        lifetimeEarnedPoints: (
          claimedTotalPointsBigInt + BigInt(maturedUnclaimedPoints)
        ).toString(),
      },
      nextSession: nextSessionState,
    };
  }

  /**
   * Result for a claim where every candidate cycle had already passed its
   * window. The cycles are settled as forfeited before we get here, so this is
   * a terminal, honest answer — not the old state-free 409 that left the
   * account wedged.
   */
  private async buildExpiredClaimResult(
    userId: string,
    asOf: Date,
    config: EffectiveMiningConfig,
    forfeited: ForfeitedCycle[],
  ) {
    const forfeitedPoints = forfeited.reduce(
      (total, cycle) => total + cycle.forfeitedPoints,
      0,
    );

    const nextSessionState = await this.ensureNextSessionState(
      userId,
      config,
      'auto_after_expiry',
    );

    const [profile, maturedUnclaimedAggregate] = await Promise.all([
      this.prisma.profile.findUnique({
        where: { id: userId },
        select: { miningClaimedPoints: true },
      }),
      this.prisma.miningHourlyCheckpoint.aggregate({
        where: {
          userId,
          ...UNSETTLED,
          hourEndAt: {
            lte: asOf,
          },
        },
        _sum: {
          points: true,
        },
      }),
    ]);

    const claimedTotalPointsBigInt = profile?.miningClaimedPoints ?? 0n;
    const maturedUnclaimedPoints = maturedUnclaimedAggregate._sum.points ?? 0;

    return {
      ok: false,
      status: 'expired' as const,
      code: 'claim_window_expired',
      message:
        forfeited.length === 1
          ? `That mining cycle expired. Cycles must be claimed within ${config.claimWindowHours} hours of completing.`
          : `${forfeited.length} mining cycles expired. Cycles must be claimed within ${config.claimWindowHours} hours of completing.`,
      claimedPoints: 0,
      forfeitedPoints,
      expiredCycles: forfeited.map(toExpiredCycleDto),
      balance: {
        claimedTotalPoints: claimedTotalPointsBigInt.toString(),
        maturedUnclaimedPoints,
        lifetimeEarnedPoints: (
          claimedTotalPointsBigInt + BigInt(maturedUnclaimedPoints)
        ).toString(),
      },
      nextSession: nextSessionState,
    };
  }

  /**
   * Returns the session the user should see next: the running one if any,
   * otherwise a freshly opened cycle. Never opens a cycle while a claimable
   * one is still outstanding.
   */
  private async ensureNextSessionState(
    userId: string,
    config: EffectiveMiningConfig,
    trigger: 'auto_after_claim' | 'auto_after_expiry',
  ) {
    if (!config.enabled) {
      return null;
    }

    const asOf = new Date();
    const unsettled = await this.prisma.miningSession.findMany({
      where: {
        userId,
        ...UNSETTLED,
      },
      orderBy: {
        startsAt: 'desc',
      },
      take: 10,
    });

    const running = unsettled.find(
      (session) => session.endsAt.getTime() > asOf.getTime(),
    );

    if (running) {
      return this.toSessionState(userId, running, asOf, config);
    }

    const stillClaimable = unsettled.find((session) =>
      isClaimable(session, asOf, config),
    );

    if (stillClaimable) {
      return null;
    }

    const nextSession = await this.createMiningSession(
      userId,
      config,
      asOf,
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
        trigger,
      },
    });

    return this.toSessionState(
      userId,
      nextSession,
      asOf,
      config,
      nextSession.activeReferralsSnapshot,
    );
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
        ...UNSETTLED,
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
          ...UNSETTLED,
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

  /**
   * Calculate streak based on consecutive claimed sessions, not UTC days.
   * A streak is maintained if sessions are claimed in sequence without gaps.
   *
   * Algorithm:
   * 1. Get all claimed sessions ordered by endsAt DESC
   * 2. Check if each session was claimed before its claim window expired
   * 3. Count consecutive sessions working backwards from most recent
   * 4. A gap occurs when: next session endsAt + claimWindow < current session startsAt
   */
  private async getClaimStreakUtcDays(userId: string): Promise<number> {
    const config = await this.miningConfigService.getEffectiveConfig();
    const claimWindowMs = config.claimWindowHours * 60 * 60 * 1000;

    // Get claimed sessions ordered by endsAt (most recent first)
    const sessions = await this.prisma.miningSession.findMany({
      where: {
        userId,
        claimedAt: { not: null },
      },
      orderBy: { endsAt: 'desc' },
      take: 30,
      select: {
        id: true,
        startsAt: true,
        endsAt: true,
        claimedAt: true,
      },
    });

    if (sessions.length === 0) {
      return 0;
    }

    // Filter out sessions where claim window expired before claiming
    const validSessions = sessions.filter((session) => {
      if (!session.claimedAt) return false;
      const claimDeadline = new Date(session.endsAt.getTime() + claimWindowMs);
      return session.claimedAt.getTime() <= claimDeadline.getTime();
    });

    if (validSessions.length === 0) {
      return 0;
    }

    // Count consecutive sessions working backwards from most recent
    let streak = 1;
    for (let i = 1; i < validSessions.length; i += 1) {
      const currentSession = validSessions[i - 1];
      const previousSession = validSessions[i];

      // Check if previous session connects to current session
      // Previous session should end before or around when current session started
      // We allow a grace period equal to the claim window to account for:
      // - User claiming late but within window
      // - Timezone differences
      // - Small gaps between session starts
      const gracePeriodMs = claimWindowMs;
      const previousEndWithGrace = previousSession.endsAt.getTime() + gracePeriodMs;
      const currentStart = currentSession.startsAt.getTime();

      // If previous session (with grace) ends before current session starts, it's consecutive
      if (previousEndWithGrace >= currentStart) {
        streak += 1;
      } else {
        // Gap detected - streak broken
        break;
      }
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
}

function mathFloor(value: number): number {
  return Math.floor(value);
}
