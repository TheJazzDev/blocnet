import { useQuery } from "@tanstack/react-query";
import { clientApi } from "@/lib/api-client";
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
