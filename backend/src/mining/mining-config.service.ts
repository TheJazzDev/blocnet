import { Injectable } from '@nestjs/common';
import { MiningConfig } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RuntimeFeatureFlagsService } from '../runtime-flags/runtime-feature-flags.service';
import { EffectiveMiningConfig } from './mining-calculator.service';

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
