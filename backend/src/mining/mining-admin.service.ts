import { Injectable } from '@nestjs/common';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { activeReferralWhere } from './active-referral';
import { buildLifetimeMiningTotals } from './dto/lifetime-mining-totals.dto';
import type { MiningAdminMetricsResponse } from './dto/mining-admin-metrics-response.dto';
import { EffectiveMiningConfig } from './mining-calculator.service';
import { UpdateMiningConfigDto } from './dto/update-mining-config.dto';
import {
  type AdminMiningConfig,
  MiningConfigService,
} from './mining-config.service';

type ConfigSnapshot = Record<string, string | number | boolean | null>;

/**
 * F-65: record what each patched field was and became so the console can show
 * a before -> after history. Only the keys in the patch are captured.
 */
export function buildConfigChangeDiff(
  before: object,
  after: object,
  patch: UpdateMiningConfigDto,
): { before: ConfigSnapshot; after: ConfigSnapshot } {
  const pick = (source: object, key: string) => {
    const value = (source as Record<string, unknown>)[key];
    if (value instanceof Date) return value.toISOString();
    if (
      typeof value === 'string' ||
      typeof value === 'number' ||
      typeof value === 'boolean'
    ) {
      return value;
    }
    return null;
  };
  const keys = Object.keys(patch).filter(
    (key) => (patch as Record<string, unknown>)[key] !== undefined,
  );
  return {
    before: Object.fromEntries(keys.map((key) => [key, pick(before, key)])),
    after: Object.fromEntries(keys.map((key) => [key, pick(after, key)])),
  };
}

@Injectable()
export class MiningAdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly miningConfigService: MiningConfigService,
  ) {}

  async getAdminConfig(): Promise<AdminMiningConfig> {
    const row = await this.miningConfigService.getOrCreateConfig();
    return this.miningConfigService.toAdminConfig(row);
  }

  async updateAdminConfig(
    actorId: string,
    patch: UpdateMiningConfigDto,
  ): Promise<AdminMiningConfig> {
    const defaultRow = await this.miningConfigService.getOrCreateConfig();
    const row = await this.prisma.miningConfig.upsert({
      where: { id: 'default' },
      update: { ...patch },
      create: {
        ...defaultRow,
        ...patch,
      },
    });

    await this.auditLogService.create({
      actorId,
      action: 'admin.mining.config.update',
      resourceType: 'mining_config',
      resourceId: row.id,
      metadata: {
        ...patch,
        ...buildConfigChangeDiff(defaultRow, row, patch),
      },
    });

    return this.miningConfigService.toAdminConfig(row);
  }

  async getAdminMetrics(): Promise<MiningAdminMetricsResponse> {
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
    const lifetimeTotals = buildLifetimeMiningTotals(
      lifetimeMinedAggregate._sum.points,
      lifetimeClaimedAggregate._sum.points,
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
      ...lifetimeTotals,
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

    return this.prisma.profile.count({
      where: {
        referredById: {
          not: null,
        },
        ...activeReferralWhere(asOf, config.activeReferralWindowHours),
      },
    });
  }
}
