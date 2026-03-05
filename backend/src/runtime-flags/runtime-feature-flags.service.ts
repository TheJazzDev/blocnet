import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { RuntimeFeatureConfig } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

const RUNTIME_FEATURE_CONFIG_ID = 'default';
const REFRESH_INTERVAL_MS = 15_000;

type RuntimeFeatureConfigSnapshot = {
  id: string;
  closedAlphaEnabled: boolean;
  alphaRadarEnabled: boolean;
  followPrefsEnabled: boolean;
  weeklyDigestEnabled: boolean;
  miningEnabled: boolean;
  referralsEnabled: boolean;
  updatedAt: Date;
};

export type RuntimeFeatureFlagsResponse = RuntimeFeatureConfigSnapshot;

@Injectable()
export class RuntimeFeatureFlagsService
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(RuntimeFeatureFlagsService.name);
  private runtimeConfig: RuntimeFeatureConfigSnapshot;
  private refreshHandle: NodeJS.Timeout | null = null;
  private warningLogged = false;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    this.runtimeConfig = this.readEnvDefaults();
  }

  onModuleInit(): void {
    void this.refresh();
    this.refreshHandle = setInterval(() => {
      void this.refresh();
    }, REFRESH_INTERVAL_MS);
  }

  onModuleDestroy(): void {
    if (this.refreshHandle) {
      clearInterval(this.refreshHandle);
      this.refreshHandle = null;
    }
  }

  async getConfig(): Promise<RuntimeFeatureFlagsResponse> {
    await this.refresh();
    return this.runtimeConfig;
  }

  async updateConfig(
    patch: Partial<{
      closedAlphaEnabled: boolean;
      alphaRadarEnabled: boolean;
      followPrefsEnabled: boolean;
      weeklyDigestEnabled: boolean;
      miningEnabled: boolean;
      referralsEnabled: boolean;
    }>,
  ): Promise<RuntimeFeatureFlagsResponse> {
    const row = await this.prisma.runtimeFeatureConfig.upsert({
      where: { id: RUNTIME_FEATURE_CONFIG_ID },
      update: {
        ...(patch.closedAlphaEnabled === undefined
          ? {}
          : { closedAlphaEnabled: patch.closedAlphaEnabled }),
        ...(patch.alphaRadarEnabled === undefined
          ? {}
          : { alphaRadarEnabled: patch.alphaRadarEnabled }),
        ...(patch.followPrefsEnabled === undefined
          ? {}
          : { followPrefsEnabled: patch.followPrefsEnabled }),
        ...(patch.weeklyDigestEnabled === undefined
          ? {}
          : { weeklyDigestEnabled: patch.weeklyDigestEnabled }),
        ...(patch.miningEnabled === undefined
          ? {}
          : { miningEnabled: patch.miningEnabled }),
        ...(patch.referralsEnabled === undefined
          ? {}
          : { referralsEnabled: patch.referralsEnabled }),
      },
      create: {
        id: RUNTIME_FEATURE_CONFIG_ID,
        closedAlphaEnabled:
          patch.closedAlphaEnabled ?? this.runtimeConfig.closedAlphaEnabled,
        alphaRadarEnabled:
          patch.alphaRadarEnabled ?? this.runtimeConfig.alphaRadarEnabled,
        followPrefsEnabled:
          patch.followPrefsEnabled ?? this.runtimeConfig.followPrefsEnabled,
        weeklyDigestEnabled:
          patch.weeklyDigestEnabled ?? this.runtimeConfig.weeklyDigestEnabled,
        miningEnabled: patch.miningEnabled ?? this.runtimeConfig.miningEnabled,
        referralsEnabled:
          patch.referralsEnabled ?? this.runtimeConfig.referralsEnabled,
      },
    });

    this.runtimeConfig = this.toSnapshot(row);
    this.warningLogged = false;
    return this.runtimeConfig;
  }

  isAlphaRadarEnabled(): boolean {
    return this.runtimeConfig.alphaRadarEnabled;
  }

  isClosedAlphaEnabled(): boolean {
    return this.runtimeConfig.closedAlphaEnabled;
  }

  isFollowPrefsEnabled(): boolean {
    return this.runtimeConfig.followPrefsEnabled;
  }

  isWeeklyDigestEnabled(): boolean {
    return this.runtimeConfig.weeklyDigestEnabled;
  }

  isMiningEnabled(): boolean {
    return this.runtimeConfig.miningEnabled;
  }

  isReferralsEnabled(): boolean {
    return this.runtimeConfig.referralsEnabled;
  }

  private async refresh(): Promise<void> {
    try {
      const row = await this.prisma.runtimeFeatureConfig.upsert({
        where: { id: RUNTIME_FEATURE_CONFIG_ID },
        update: {},
        create: {
          id: RUNTIME_FEATURE_CONFIG_ID,
          closedAlphaEnabled: this.runtimeConfig.closedAlphaEnabled,
          alphaRadarEnabled: this.runtimeConfig.alphaRadarEnabled,
          followPrefsEnabled: this.runtimeConfig.followPrefsEnabled,
          weeklyDigestEnabled: this.runtimeConfig.weeklyDigestEnabled,
          miningEnabled: this.runtimeConfig.miningEnabled,
          referralsEnabled: this.runtimeConfig.referralsEnabled,
        },
      });
      this.runtimeConfig = this.toSnapshot(row);
      this.warningLogged = false;
    } catch (error) {
      if (!this.warningLogged) {
        this.warningLogged = true;
        this.logger.warn(
          `Runtime feature flags unavailable, using env defaults: ${this.errorMessage(
            error,
          )}`,
        );
      }
    }
  }

  private toSnapshot(row: RuntimeFeatureConfig): RuntimeFeatureConfigSnapshot {
    return {
      id: row.id,
      closedAlphaEnabled: row.closedAlphaEnabled,
      alphaRadarEnabled: row.alphaRadarEnabled,
      followPrefsEnabled: row.followPrefsEnabled,
      weeklyDigestEnabled: row.weeklyDigestEnabled,
      miningEnabled: row.miningEnabled,
      referralsEnabled: row.referralsEnabled,
      updatedAt: row.updatedAt,
    };
  }

  private readEnvDefaults(): RuntimeFeatureConfigSnapshot {
    return {
      id: RUNTIME_FEATURE_CONFIG_ID,
      closedAlphaEnabled: this.getBoolean('ENABLE_CLOSED_ALPHA', false),
      alphaRadarEnabled: this.getBoolean('ENABLE_ALPHA_RADAR', true),
      followPrefsEnabled: this.getBoolean('ENABLE_FOLLOW_PREFS', true),
      weeklyDigestEnabled: this.getBoolean('ENABLE_WEEKLY_DIGEST', true),
      miningEnabled: this.getBoolean('ENABLE_MINING', true),
      referralsEnabled: this.getBoolean('ENABLE_REFERRALS', true),
      updatedAt: new Date(),
    };
  }

  private getBoolean(key: string, fallback: boolean): boolean {
    const raw = this.configService.get<string | number | boolean>(key);
    if (raw === undefined || raw === null) {
      return fallback;
    }
    if (typeof raw === 'boolean') {
      return raw;
    }
    if (typeof raw === 'number') {
      return raw !== 0;
    }
    const normalized = raw.trim().toLowerCase();
    if (normalized === 'true' || normalized === '1' || normalized === 'yes') {
      return true;
    }
    if (normalized === 'false' || normalized === '0' || normalized === 'no') {
      return false;
    }
    return fallback;
  }

  private errorMessage(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }
    return String(error);
  }
}
