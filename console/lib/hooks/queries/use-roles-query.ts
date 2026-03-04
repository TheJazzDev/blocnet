import { useQuery } from "@tanstack/react-query";
import { clientApi, type RolesMatrixResponse } from "@/lib/api-client";
import { queryKeys } from "./query-keys";
import { queryOptions } from "./query-options";

/**
 * Query hook for fetching roles matrix
 *
 * Roles matrix rarely changes, so we use static caching (5 min stale time).
 *
 * @example
 * const { data: rolesMatrix, isLoading } = useRolesQuery();
 */
export function useRolesQuery() {
  return useQuery({
    queryKey: queryKeys.roles.matrix(),
    queryFn: () => clientApi.getRolesMatrix(),
    ...queryOptions.static, // Rarely changes
  });
}
