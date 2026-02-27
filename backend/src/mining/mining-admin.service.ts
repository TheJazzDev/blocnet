import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  EffectiveMiningConfig,
  MiningCalculatorService,
} from './mining-calculator.service';
import { MiningConfigService } from './mining-config.service';

@Injectable()
export class MiningAdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly miningConfigService: MiningConfigService,
  ) {}

  async getAdminConfig() {
    return this.miningConfigService.getEffectiveConfig();
  }

  async updateAdminConfig(
    actorId: string,
    patch: Partial<EffectiveMiningConfig>,
  ) {
    const defaultRow = await this.miningConfigService.getOrCreateConfig();
    const row = await this.prisma.miningConfig.upsert({
      where: { id: 'default' },
      update: patch,
      create: {
        ...defaultRow,
        ...patch,
      },
    });

    const config = this.miningConfigService.withEnvFlagOverrides(row);

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
    const config = await this.miningConfigService.getEffectiveConfig();

    const [
      dauMinersRows,
      startsDay,
      claimsDay,
      avgBoost,
      totalProfiles,
      totalBoundProfiles,
      activeDirectReferrals,
      lifetimeMinedAggregate,
      lifetimeClaimedAggregate,
      lifetimeMinersRows,
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
      this.prisma.miningHourlyCheckpoint.aggregate({
        _sum: {
          points: true,
        },
      }),
      this.prisma.miningHourlyCheckpoint.aggregate({
        where: {
          claimedAt: {
            not: null,
          },
        },
        _sum: {
          points: true,
        },
      }),
      this.prisma.miningHourlyCheckpoint.findMany({
        select: {
          userId: true,
        },
        distinct: ['userId'],
      }),
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
    const lifetimeMinedMcr = lifetimeMinedAggregate._sum.points ?? 0;
    const lifetimeClaimedMcr = lifetimeClaimedAggregate._sum.points ?? 0;
    const lifetimeUnclaimedMcr = Math.max(
      lifetimeMinedMcr - lifetimeClaimedMcr,
      0,
    );

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
      lifetimeMinedMcr,
      lifetimeClaimedMcr,
      lifetimeUnclaimedMcr,
      totalMiners: lifetimeMinersRows.length,
    };
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
}
