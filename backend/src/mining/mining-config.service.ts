import { Injectable } from '@nestjs/common';
import { MiningConfig } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RuntimeFeatureFlagsService } from '../runtime-flags/runtime-feature-flags.service';
import { EffectiveMiningConfig } from './mining-calculator.service';

/**
 * What GET/PATCH /admin/mining/config return (F-47). `enabled` and
 * `referralsEnabled` are the raw stored values; the env kill-switches travel
 * separately in `runtimeFlags`, so a console that saves what it loaded can
 * never persist flag-ANDed values.
 */
export type AdminMiningConfig = EffectiveMiningConfig & {
  runtimeFlags: { miningEnabled: boolean; referralsEnabled: boolean };
  updatedAt: string;
};

export const DEFAULT_MINING_CONFIG: EffectiveMiningConfig = {
  enabled: true,
  referralsEnabled: true,
  cycleHours: 24,
  basePointsPerCycle: 120,
  perActiveReferralBoostBps: 500,
  maxBoostBps: 10000,
  activeReferralWindowHours: 168,
  referralBindWindowHours: 24,
  claimWindowHours: 48,
};

@Injectable()
export class MiningConfigService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly runtimeFeatureFlagsService: RuntimeFeatureFlagsService,
  ) {}

  async getEffectiveConfig(): Promise<EffectiveMiningConfig> {
    const row = await this.getOrCreateConfig();
    return this.withEnvFlagOverrides(row);
  }

  async getOrCreateConfig(): Promise<MiningConfig> {
    return this.prisma.miningConfig.upsert({
      where: { id: 'default' },
      update: {},
      create: {
        id: 'default',
        ...DEFAULT_MINING_CONFIG,
      },
    });
  }

  toAdminConfig(row: MiningConfig): AdminMiningConfig {
    return {
      enabled: row.enabled,
      referralsEnabled: row.referralsEnabled,
      cycleHours: row.cycleHours,
      basePointsPerCycle: row.basePointsPerCycle,
      perActiveReferralBoostBps: row.perActiveReferralBoostBps,
      maxBoostBps: row.maxBoostBps,
      activeReferralWindowHours: row.activeReferralWindowHours,
      referralBindWindowHours: row.referralBindWindowHours,
      claimWindowHours: row.claimWindowHours,
      runtimeFlags: {
        miningEnabled: this.runtimeFeatureFlagsService.isMiningEnabled(),
        referralsEnabled: this.runtimeFeatureFlagsService.isReferralsEnabled(),
      },
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  withEnvFlagOverrides(config: MiningConfig): EffectiveMiningConfig {
    const miningEnabledFlag = this.runtimeFeatureFlagsService.isMiningEnabled();
    const referralsEnabledFlag =
      this.runtimeFeatureFlagsService.isReferralsEnabled();

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
      claimWindowHours: config.claimWindowHours,
    };
  }
}
