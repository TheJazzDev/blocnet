import { useQuery } from "@tanstack/react-query";
import { clientApi, type AdminStats } from "@/lib/api-client";
import { queryKeys } from "./query-keys";
import { queryOptions } from "./query-options";

/**
 * Query hook for fetching dashboard stats
 *
 * @param options - Optional configuration
 * @param options.refetchInterval - Auto-refetch interval in ms (default: none)
 *
 * @example
 * // Basic usage
 * const { data: stats, isLoading } = useStatsQuery();
 *
 * @example
 * // With auto-refresh every 30 seconds
 * const { data: stats } = useStatsQuery({ refetchInterval: 30_000 });
 */
export function useStatsQuery(options?: { refetchInterval?: number }) {
  return useQuery({
    queryKey: queryKeys.stats.dashboard(),
    queryFn: () => clientApi.getStats(),
    ...queryOptions.standard,
    refetchInterval: options?.refetchInterval,
  });
}
