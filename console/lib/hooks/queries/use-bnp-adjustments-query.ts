import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { clientApi, type AdminBnpAdjustmentRequest } from "@/lib/api-client";
import { queryKeys } from "./query-keys";
import { queryOptions } from "./query-options";

/** F-66: a member's manual BNP adjustments, newest first. */
export function useBnpAdjustmentsQuery(
  userId: string,
  options?: { enabled?: boolean; limit?: number; offset?: number },
) {
  const params = { limit: options?.limit ?? 10, offset: options?.offset ?? 0 };
  return useQuery({
    queryKey: queryKeys.mining.adjustments(userId, params),
    queryFn: () => clientApi.listBnpAdjustments(userId, params),
    enabled: Boolean(userId) && (options?.enabled ?? true),
    ...queryOptions.standard,
  });
}

/** Credits or debits a member, then refreshes their mining data and history. */
export function useCreateBnpAdjustmentMutation(userId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (body: AdminBnpAdjustmentRequest) =>
      clientApi.createBnpAdjustment(userId, body),
    onSuccess: () => {
      void queryClient.invalidateQueries({
        queryKey: queryKeys.mining.adjustmentsFor(userId),
      });
      void queryClient.invalidateQueries({ queryKey: queryKeys.users.detail(userId) });
      void queryClient.invalidateQueries({ queryKey: [...queryKeys.mining.all, "leaderboard"] });
      void queryClient.invalidateQueries({ queryKey: queryKeys.mining.metrics() });
    },
  });
}
