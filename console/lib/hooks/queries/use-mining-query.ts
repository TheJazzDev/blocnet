import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { clientApi, type AdminMiningConfigPatch } from "@/lib/api-client";
import { MINING_CONFIG_UPDATE_ACTION } from "@/lib/api/mining-config-history";
import { queryKeys } from "./query-keys";
import { queryOptions } from "./query-options";

/**
 * Query hook for getting mining leaderboard
 */
export function useMiningLeaderboardQuery(params?: {
  q?: string;
  limit?: number;
  offset?: number;
}) {
  return useQuery({
    queryKey: queryKeys.mining.leaderboard(params ?? {}),
    queryFn: () => clientApi.getMiningLeaderboard(params),
    ...queryOptions.standard,
  });
}

/** Stored mining config plus the runtime flags that gate it. */
export function useMiningConfigQuery(options?: { enabled?: boolean }) {
  return useQuery({
    queryKey: queryKeys.mining.config(),
    queryFn: () => clientApi.getMiningConfig(),
    enabled: options?.enabled ?? true,
    ...queryOptions.standard,
  });
}

/** Mining engagement metrics (mix of rolling-24h and lifetime values). */
export function useMiningMetricsQuery(options?: { enabled?: boolean }) {
  return useQuery({
    queryKey: queryKeys.mining.metrics(),
    queryFn: () => clientApi.getMiningMetrics(),
    enabled: options?.enabled ?? true,
    ...queryOptions.standard,
  });
}

/** Most recent mining config changes from the audit log, newest first. */
export function useMiningConfigHistoryQuery(options?: { enabled?: boolean; limit?: number }) {
  const limit = options?.limit ?? 20;
  return useQuery({
    queryKey: queryKeys.mining.configHistory({ limit }),
    queryFn: () =>
      clientApi.listAuditLog(limit, 0, { actions: [MINING_CONFIG_UPDATE_ACTION] }),
    enabled: options?.enabled ?? true,
    ...queryOptions.standard,
  });
}

/** PATCH only the changed config fields, then refresh config, metrics and history. */
export function useUpdateMiningConfigMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (patch: AdminMiningConfigPatch) => clientApi.updateMiningConfig(patch),
    onSuccess: (next) => {
      queryClient.setQueryData(queryKeys.mining.config(), next);
      void queryClient.invalidateQueries({ queryKey: queryKeys.mining.config() });
      void queryClient.invalidateQueries({ queryKey: queryKeys.mining.metrics() });
      void queryClient.invalidateQueries({ queryKey: queryKeys.mining.configHistories() });
    },
  });
}
