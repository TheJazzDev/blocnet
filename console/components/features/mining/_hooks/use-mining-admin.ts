"use client";

import { useEffect, useState } from "react";
import {
  clientApi,
  type AdminMiningConfig,
  type AdminMiningMetrics,
} from "@/lib/api-client";

export function useMiningAdmin() {
  const [config, setConfig] = useState<AdminMiningConfig | null>(null);
  const [metrics, setMetrics] = useState<AdminMiningMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const [cfg, m] = await Promise.all([
        clientApi.getMiningConfig(),
        clientApi.getMiningMetrics(),
      ]);
      setConfig(cfg);
      setMetrics(m);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load mining settings");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

  async function save() {
    if (!config) return;
    setSaving(true);
    setError(null);
    try {
      const next = await clientApi.updateMiningConfig(config);
      setConfig(next);
      setMetrics(await clientApi.getMiningMetrics());
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save mining settings");
    } finally {
      setSaving(false);
    }
  }

  return {
    config,
    setConfig,
    metrics,
    loading,
    saving,
    error,
    load,
    save,
  };
}
