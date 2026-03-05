"use client";

import { useEffect, useState } from "react";
import {
  clientApi,
  type ClosedAlphaEmailRecord,
  type ClosedAlphaEmailsResponse,
  type RuntimeFeatureFlagsConfig,
} from "@/lib/api-client";

type RuntimeFlagKey = keyof Pick<
  RuntimeFeatureFlagsConfig,
  | "closedAlphaEnabled"
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
  const [closedAlphaEmails, setClosedAlphaEmails] = useState<
    ClosedAlphaEmailRecord[]
  >([]);
  const [closedAlphaTotal, setClosedAlphaTotal] = useState(0);
  const [closedAlphaLoading, setClosedAlphaLoading] = useState(true);
  const [closedAlphaMutating, setClosedAlphaMutating] = useState(false);
  const [closedAlphaStatus, setClosedAlphaStatus] = useState<string | null>(null);

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
        closedAlphaEnabled: runtimeFlags.closedAlphaEnabled,
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

  async function loadClosedAlphaEmails() {
    setClosedAlphaLoading(true);
    setClosedAlphaStatus(null);
    try {
      const result: ClosedAlphaEmailsResponse =
        await clientApi.listClosedAlphaEmails({
          limit: 100,
          offset: 0,
        });
      setClosedAlphaEmails(result.data);
      setClosedAlphaTotal(result.total);
    } catch (error) {
      setClosedAlphaStatus(
        error instanceof Error
          ? error.message
          : "Failed to load closed alpha emails",
      );
      setClosedAlphaEmails([]);
      setClosedAlphaTotal(0);
    } finally {
      setClosedAlphaLoading(false);
    }
  }

  async function addClosedAlphaEmail(email: string, note?: string) {
    setClosedAlphaMutating(true);
    setClosedAlphaStatus(null);
    try {
      await clientApi.createClosedAlphaEmail({
        email,
        ...(note && note.trim().length > 0 ? { note: note.trim() } : {}),
      });
      setClosedAlphaStatus("Closed alpha email saved.");
      await loadClosedAlphaEmails();
    } catch (error) {
      setClosedAlphaStatus(
        error instanceof Error ? error.message : "Failed to save email",
      );
    } finally {
      setClosedAlphaMutating(false);
    }
  }

  async function removeClosedAlphaEmail(id: string) {
    setClosedAlphaMutating(true);
    setClosedAlphaStatus(null);
    try {
      await clientApi.deleteClosedAlphaEmail(id);
      setClosedAlphaStatus("Closed alpha email removed.");
      await loadClosedAlphaEmails();
    } catch (error) {
      setClosedAlphaStatus(
        error instanceof Error ? error.message : "Failed to remove email",
      );
    } finally {
      setClosedAlphaMutating(false);
    }
  }

  async function setClosedAlphaEmailActive(id: string, isActive: boolean) {
    setClosedAlphaMutating(true);
    setClosedAlphaStatus(null);
    try {
      await clientApi.updateClosedAlphaEmailStatus(id, { isActive });
      setClosedAlphaStatus("Closed alpha email updated.");
      await loadClosedAlphaEmails();
    } catch (error) {
      setClosedAlphaStatus(
        error instanceof Error ? error.message : "Failed to update email status",
      );
    } finally {
      setClosedAlphaMutating(false);
    }
  }

  useEffect(() => {
    void loadRuntimeFlags();
    void loadClosedAlphaEmails();
  }, []);

  return {
    runtimeFlags,
    runtimeFlagsLoading,
    runtimeFlagsSaving,
    runtimeFlagsStatus,
    loadRuntimeFlags,
    saveRuntimeFlags,
    setRuntimeFlag,
    closedAlphaEmails,
    closedAlphaTotal,
    closedAlphaLoading,
    closedAlphaMutating,
    closedAlphaStatus,
    loadClosedAlphaEmails,
    addClosedAlphaEmail,
    removeClosedAlphaEmail,
    setClosedAlphaEmailActive,
  };
}
