import { describe, expect, it } from "vitest";
import { diffMiningConfig, effectiveMiningFlags } from "./mining-config";
import type { AdminMiningConfig } from "./server-types-tips-mining";

const base: AdminMiningConfig = {
  enabled: true,
  referralsEnabled: true,
  cycleHours: 24,
  basePointsPerCycle: 120,
  perActiveReferralBoostBps: 500,
  maxBoostBps: 5000,
  activeReferralWindowHours: 168,
  referralBindWindowHours: 72,
  claimWindowHours: 48,
  runtimeFlags: { miningEnabled: true, referralsEnabled: true },
  updatedAt: "2026-09-16T00:00:00.000Z",
};

describe("diffMiningConfig", () => {
  it("returns an empty patch when nothing changed", () => {
    expect(diffMiningConfig(base, { ...base })).toEqual({});
  });

  it("sends only the fields the admin changed", () => {
    expect(
      diffMiningConfig(base, { ...base, claimWindowHours: 72, enabled: false }),
    ).toEqual({ claimWindowHours: 72, enabled: false });
  });

  it("never sends read-only fields", () => {
    const draft = {
      ...base,
      runtimeFlags: { miningEnabled: false, referralsEnabled: false },
      updatedAt: "2026-09-17T00:00:00.000Z",
    };
    expect(diffMiningConfig(base, draft)).toEqual({});
  });

  it("does not send claimWindowHours when an old backend omits it", () => {
    const legacy = { ...base } as Partial<AdminMiningConfig>;
    delete legacy.claimWindowHours;
    const legacyConfig = legacy as AdminMiningConfig;
    expect(diffMiningConfig(legacyConfig, { ...legacyConfig, cycleHours: 12 })).toEqual({
      cycleHours: 12,
    });
  });
});

describe("effectiveMiningFlags", () => {
  it("is on when stored and runtime are both on", () => {
    const flags = effectiveMiningFlags(base);
    expect(flags.mining).toEqual({
      stored: true,
      runtime: true,
      effective: true,
      overriddenByRuntime: false,
    });
  });

  it("flags a runtime override when the stored value is on", () => {
    const flags = effectiveMiningFlags({
      ...base,
      runtimeFlags: { miningEnabled: true, referralsEnabled: false },
    });
    expect(flags.referrals.effective).toBe(false);
    expect(flags.referrals.overriddenByRuntime).toBe(true);
    expect(flags.mining.overriddenByRuntime).toBe(false);
  });

  it("is off without an override note when stored is off", () => {
    const flags = effectiveMiningFlags({
      ...base,
      enabled: false,
      runtimeFlags: { miningEnabled: false, referralsEnabled: true },
    });
    expect(flags.mining.effective).toBe(false);
    expect(flags.mining.overriddenByRuntime).toBe(false);
  });

  it("falls back to the stored value when runtimeFlags is missing", () => {
    const legacy = { ...base, runtimeFlags: undefined };
    const flags = effectiveMiningFlags(legacy);
    expect(flags.mining).toEqual({
      stored: true,
      runtime: null,
      effective: true,
      overriddenByRuntime: false,
    });
  });
});
