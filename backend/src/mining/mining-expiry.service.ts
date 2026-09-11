import { Injectable, Logger } from '@nestjs/common';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  applyExpirySettlement,
  computeClaimDeadline,
  type ClaimWindowConfig,
} from './mining-settlement';

export const MINING_CYCLE_EXPIRED_ACTION = 'mining.cycle.expired';

export type ForfeitedCycle = {
  sessionId: string;
  startsAt: Date;
  endsAt: Date;
  claimDeadline: Date;
  expiredAt: Date;
  forfeitedPoints: number;
  checkpointCount: number;
};

/**
 * Reconciles cycles whose claim window elapsed unclaimed.
 *
 * Before F-39 nothing ever gave such a cycle a terminal state, so `claim()`
 * re-selected it forever (throwing `claim_window_expired`) while `start()`
 * refused to open a new cycle (throwing `claim_required`) — a permanent
 * lockout. Every read and write of mining state now settles first, so the
 * deadlock cannot form again.
 */
@Injectable()
export class MiningExpiryService {
  private readonly logger = new Logger(MiningExpiryService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  /**
   * Cutoff before which an ended-but-unclaimed cycle is past its window.
   * `endsAt < cutoff` is equivalent to `asOf > endsAt + claimWindowHours`.
   */
  expiryCutoff(asOf: Date, config: ClaimWindowConfig): Date {
    return new Date(
      asOf.getTime() - Math.max(config.claimWindowHours, 0) * 60 * 60 * 1000,
    );
  }

  /**
   * Settles every unclaimed, unexpired cycle of a user whose window has
   * elapsed. Idempotent: the update is guarded on both terminal columns being
   * null, so a concurrent caller settles at most once.
   */
  async settleExpiredForUser(
    userId: string,
    asOf: Date,
    config: ClaimWindowConfig,
  ): Promise<ForfeitedCycle[]> {
    const sessions = await this.prisma.miningSession.findMany({
      where: {
        userId,
        claimedAt: null,
        expiredAt: null,
        endsAt: {
          lt: this.expiryCutoff(asOf, config),
        },
      },
      orderBy: {
        startsAt: 'asc',
      },
      select: {
        id: true,
        startsAt: true,
        endsAt: true,
      },
    });

    if (sessions.length === 0) {
      return [];
    }

    const forfeited: ForfeitedCycle[] = [];

    for (const session of sessions) {
      const accrual = await this.prisma.miningHourlyCheckpoint.aggregate({
        where: {
          sessionId: session.id,
          claimedAt: null,
          expiredAt: null,
        },
        _sum: { points: true },
        _count: { _all: true },
      });

      const settled = await this.prisma.$transaction((tx) =>
        applyExpirySettlement(tx, { sessionId: session.id, expiredAt: asOf }),
      );

      if (!settled) {
        continue;
      }

      const cycle: ForfeitedCycle = {
        sessionId: session.id,
        startsAt: session.startsAt,
        endsAt: session.endsAt,
        claimDeadline: computeClaimDeadline(session.endsAt, config),
        expiredAt: asOf,
        forfeitedPoints: accrual._sum.points ?? 0,
        checkpointCount: accrual._count._all,
      };
      forfeited.push(cycle);

      await this.auditLogService.create({
        actorId: userId,
        action: MINING_CYCLE_EXPIRED_ACTION,
        resourceType: 'mining_session',
        resourceId: session.id,
        metadata: {
          endsAt: session.endsAt.toISOString(),
          claimDeadline: cycle.claimDeadline.toISOString(),
          expiredAt: asOf.toISOString(),
          forfeitedPoints: cycle.forfeitedPoints,
          hourlyCheckpointCount: cycle.checkpointCount,
          claimWindowHours: config.claimWindowHours,
        },
      });
    }

    if (forfeited.length > 0) {
      this.logger.log(
        `Forfeited ${forfeited.length} expired mining cycle(s) for user ${userId}`,
      );
    }

    return forfeited;
  }
}
