"use client";

import { useEffect, useState } from "react";
import {
  clientApi,
  type RuntimeFeatureFlagsConfig,
} from "@/lib/api-client";

type RuntimeFlagKey = keyof Pick<
  RuntimeFeatureFlagsConfig,
  | "alphaRadarEnabled"
  | "followPrefsEnabled"
  | "weeklyDigestEnabled"
  | "miningEnabled"
  | "referralsEnabled"
>;

export function useRuntimeFeatureFlags() {
  const [runtimeFlags, setRuntimeFlags] =
    useState<RuntimeFeatureFlagsConfig | null>(null);
  const [runtimeFlagsLoading, setRuntimeFlagsLoading] = useState(true);
  const [runtimeFlagsSaving, setRuntimeFlagsSaving] = useState(false);
  const [runtimeFlagsStatus, setRuntimeFlagsStatus] = useState<string | null>(
    null,
  );

  async function loadRuntimeFlags() {
    setRuntimeFlagsLoading(true);
    setRuntimeFlagsStatus(null);
    try {
      const config = await clientApi.getRuntimeFeatureFlags();
      setRuntimeFlags(config);
    } catch (error) {
      setRuntimeFlags(null);
      setRuntimeFlagsStatus(
        error instanceof Error
          ? error.message
          : "Failed to load runtime feature flags",
      );
    } finally {
      setRuntimeFlagsLoading(false);
    }
  }

  async function saveRuntimeFlags() {
    if (!runtimeFlags) return;
    setRuntimeFlagsSaving(true);
    setRuntimeFlagsStatus(null);
    try {
      const updated = await clientApi.updateRuntimeFeatureFlags({
        alphaRadarEnabled: runtimeFlags.alphaRadarEnabled,
        followPrefsEnabled: runtimeFlags.followPrefsEnabled,
        weeklyDigestEnabled: runtimeFlags.weeklyDigestEnabled,
        miningEnabled: runtimeFlags.miningEnabled,
        referralsEnabled: runtimeFlags.referralsEnabled,
      });
      setRuntimeFlags(updated);
      setRuntimeFlagsStatus("Runtime feature flags saved.");
    } catch (error) {
      setRuntimeFlagsStatus(
        error instanceof Error
          ? error.message
          : "Failed to save runtime feature flags",
      );
    } finally {
      setRuntimeFlagsSaving(false);
    }
  }

  function setRuntimeFlag(key: RuntimeFlagKey, enabled: boolean) {
    setRuntimeFlags((prev) => (prev ? { ...prev, [key]: enabled } : prev));
  }

  useEffect(() => {
    void loadRuntimeFlags();
  }, []);

  return {
    runtimeFlags,
    runtimeFlagsLoading,
    runtimeFlagsSaving,
    runtimeFlagsStatus,
    loadRuntimeFlags,
    saveRuntimeFlags,
    setRuntimeFlag,
  };
}
