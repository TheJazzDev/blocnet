"use client";

import { useCallback, useEffect } from "react";
import { useStatsStore } from "@/lib/stores";
import { clientApi } from "@/lib/api-client";

interface UseStatsOptions {
  autoLoad?: boolean;
  refreshInterval?: number;
}

/**
 * Hook to manage dashboard stats
 */
export function useStats(options: UseStatsOptions = {}) {
  const { autoLoad = true, refreshInterval } = options;
  const { stats, isLoading, error, setStats, setLoading, setError, shouldRefresh } =
    useStatsStore();

  const loadStats = useCallback(
    async (force = false) => {
      if (!force && !shouldRefresh()) {
        return;
      }

      setLoading(true);
      try {
        const data = await clientApi.getStats();
        setStats(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Failed to load stats");
      }
    },
    [setStats, setLoading, setError, shouldRefresh]
  );

  useEffect(() => {
    if (autoLoad) {
      void loadStats();
    }
  }, [autoLoad, loadStats]);

  useEffect(() => {
    if (!refreshInterval) return;

    const interval = setInterval(() => {
      void loadStats();
    }, refreshInterval);

    return () => clearInterval(interval);
  }, [refreshInterval, loadStats]);

  return {
    stats,
    isLoading,
    error,
    loadStats,
    refresh: () => loadStats(true),
  };
}
