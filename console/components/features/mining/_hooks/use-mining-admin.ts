"use client";

import { useMemo, useState } from "react";
import type { AdminMiningConfig, AdminMiningConfigPatch } from "@/lib/api-client";
import { diffMiningConfig } from "@/lib/api/mining-config";
import {
  useMiningConfigQuery,
  useMiningMetricsQuery,
  useUpdateMiningConfigMutation,
} from "@/lib/hooks/queries";

function errorMessage(err: unknown, fallback: string): string | null {
  if (!err) return null;
  return err instanceof Error ? err.message : fallback;
}

/**
 * Server state comes from TanStack Query; the form keeps only the admin's
 * pending edits, so saving sends exactly the fields that changed.
 */
export function useMiningAdmin(options?: { enabled?: boolean }) {
  const enabled = options?.enabled ?? true;
  const configQuery = useMiningConfigQuery({ enabled });
  const metricsQuery = useMiningMetricsQuery({ enabled });
  const mutation = useUpdateMiningConfigMutation();
  const [edits, setEdits] = useState<AdminMiningConfigPatch>({});

  const serverConfig = configQuery.data ?? null;
  const draft = useMemo<AdminMiningConfig | null>(
    () => (serverConfig ? { ...serverConfig, ...edits } : null),
    [serverConfig, edits],
  );
  const patch = useMemo(
    () => (serverConfig && draft ? diffMiningConfig(serverConfig, draft) : {}),
    [serverConfig, draft],
  );
  const dirty = Object.keys(patch).length > 0;

  function setField<K extends keyof AdminMiningConfigPatch>(
    key: K,
    value: NonNullable<AdminMiningConfigPatch[K]>,
  ) {
    setEdits((prev) => ({ ...prev, [key]: value }));
  }

  async function save() {
    if (!dirty) return;
    try {
      await mutation.mutateAsync(patch);
      setEdits({});
    } catch {
      // Surfaced through `error` below.
    }
  }

  async function refresh() {
    await Promise.all([configQuery.refetch(), metricsQuery.refetch()]);
  }

  const error =
    errorMessage(mutation.error, "Failed to save mining settings") ??
    errorMessage(configQuery.error ?? metricsQuery.error, "Failed to load mining settings");

  return {
    config: draft,
    serverConfig,
    metrics: metricsQuery.data ?? null,
    loading: configQuery.isLoading || metricsQuery.isLoading,
    refreshing: configQuery.isFetching || metricsQuery.isFetching,
    saving: mutation.isPending,
    dirty,
    changedFields: Object.keys(patch),
    error,
    setField,
    reset: () => setEdits({}),
    refresh,
    save,
  };
}
