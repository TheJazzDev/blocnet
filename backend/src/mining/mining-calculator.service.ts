import { Injectable } from '@nestjs/common';

export type EffectiveMiningConfig = {
  enabled: boolean;
  referralsEnabled: boolean;
  cycleHours: number;
  basePointsPerCycle: number;
  perActiveReferralBoostBps: number;
  maxBoostBps: number;
  activeReferralWindowHours: number;
  referralBindWindowHours: number;
};

@Injectable()
export class MiningCalculatorService {
  computeSessionCycleHours(startsAt: Date, endsAt: Date): number {
    const durationMs = endsAt.getTime() - startsAt.getTime();
    if (durationMs <= 0) return 1;

    return Math.max(1, Math.round(durationMs / (60 * 60 * 1000)));
  }

  computeMaturedHours(
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

  computeElapsedHours(startsAt: Date, endsAt: Date, asOf: Date): number {
    const cappedEndMs = Math.min(asOf.getTime(), endsAt.getTime());
    const elapsedMs = cappedEndMs - startsAt.getTime();
    if (elapsedMs <= 0) {
      return 0;
    }

    const cycleHours = this.computeSessionCycleHours(startsAt, endsAt);
    return Math.min(cycleHours, elapsedMs / (60 * 60 * 1000));
  }

  computeProgressPct(startsAt: Date, endsAt: Date, asOf: Date): number {
    const durationMs = endsAt.getTime() - startsAt.getTime();
    if (durationMs <= 0) return 1;

    const elapsedMs = asOf.getTime() - startsAt.getTime();
    if (elapsedMs <= 0) return 0;
    if (elapsedMs >= durationMs) return 1;

    return elapsedMs / durationMs;
  }

  computeBoostBps(
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

  computeProjectedCyclePoints(
    basePointsPerCycle: number,
    boostBps: number,
  ): number {
    return Math.floor((basePointsPerCycle * (10000 + boostBps)) / 10000);
  }

  computeHourlyCheckpointPoints(
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
}
