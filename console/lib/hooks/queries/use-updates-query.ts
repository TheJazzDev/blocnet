import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { clientApi, type AdminUpdate, type UpdateStatus } from "@/lib/api-client";
import { queryKeys } from "./query-keys";
import { queryOptions } from "./query-options";

/**
 * Query hook for listing updates with filters
 */
export function useUpdatesQuery(params?: {
  q?: string;
  status?: UpdateStatus;
  projectId?: string;
  authorId?: string;
  limit?: number;
  offset?: number;
}) {
  return useQuery({
    queryKey: queryKeys.updates.list(params ?? {}),
    queryFn: () => clientApi.listAdminUpdates(params),
    ...queryOptions.standard,
  });
}

/**
 * Mutation hook for moderating update status
 */
export function useModerateUpdateMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      updateId,
      status,
      reason,
    }: {
      updateId: string;
      status: UpdateStatus;
      reason: string;
    }) => clientApi.moderateUpdateStatus(updateId, { status, reason }),

    onSuccess: (updatedUpdate) => {
      // Update the specific update in cache if it exists
      queryClient.setQueryData<AdminUpdate>(
        queryKeys.updates.detail(updatedUpdate.id),
        updatedUpdate
      );

      // Invalidate update lists to refetch with updated data
      queryClient.invalidateQueries({ queryKey: queryKeys.updates.lists() });
    },
  });
}
