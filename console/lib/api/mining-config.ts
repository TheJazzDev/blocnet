import type {
  AdminMiningConfig,
  AdminMiningConfigFields,
  AdminMiningConfigPatch,
} from "./server-types-tips-mining";

/** The editable fields, in the order the form shows them. */
export const MINING_CONFIG_FIELDS = [
  "enabled",
  "referralsEnabled",
  "cycleHours",
  "basePointsPerCycle",
  "perActiveReferralBoostBps",
  "maxBoostBps",
  "activeReferralWindowHours",
  "referralBindWindowHours",
  "claimWindowHours",
] as const satisfies readonly (keyof AdminMiningConfigFields)[];

/**
 * The PATCH body for a form edit: only the editable fields whose value
 * differs from what the server returned. Read-only fields (`runtimeFlags`,
 * `updatedAt`) are never sent.
 */
export function diffMiningConfig(
  original: AdminMiningConfig,
  draft: AdminMiningConfig,
): AdminMiningConfigPatch {
  const patch: Record<string, unknown> = {};
  for (const key of MINING_CONFIG_FIELDS) {
    if (draft[key] !== undefined && draft[key] !== original[key]) {
      patch[key] = draft[key];
    }
  }
  return patch as AdminMiningConfigPatch;
}

export type EffectiveMiningFlag = {
  /** Value stored in MiningConfig. */
  stored: boolean;
  /** Runtime flag from Settings, or null when the backend did not send one. */
  runtime: boolean | null;
  /** What members actually get: stored AND runtime. */
  effective: boolean;
  /** Stored says on, but the runtime flag switches it off. */
  overriddenByRuntime: boolean;
};

function combine(stored: boolean, runtime: boolean | undefined): EffectiveMiningFlag {
  const runtimeValue = runtime ?? null;
  const effective = stored && runtimeValue !== false;
  return {
    stored,
    runtime: runtimeValue,
    effective,
    overriddenByRuntime: stored && runtimeValue === false,
  };
}

export function effectiveMiningFlags(config: AdminMiningConfig) {
  return {
    mining: combine(config.enabled, config.runtimeFlags?.miningEnabled),
    referrals: combine(config.referralsEnabled, config.runtimeFlags?.referralsEnabled),
  };
}
