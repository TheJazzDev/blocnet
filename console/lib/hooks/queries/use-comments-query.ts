import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { clientApi, type AdminComment, type ContentStatus } from "@/lib/api-client";
import { queryKeys } from "./query-keys";
import { queryOptions } from "./query-options";

/**
 * Query hook for listing comments with filters
 */
export function useCommentsQuery(params?: {
  q?: string;
  status?: ContentStatus;
  updateId?: string;
  authorId?: string;
  limit?: number;
  offset?: number;
}) {
  return useQuery({
    queryKey: queryKeys.comments.list(params ?? {}),
    queryFn: () => clientApi.listAdminComments(params),
    ...queryOptions.standard,
  });
}

/**
 * Mutation hook for moderating comment status
 */
export function useModerateCommentMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      commentId,
      status,
      reason,
    }: {
      commentId: string;
      status: ContentStatus;
      reason: string;
    }) => clientApi.moderateCommentStatus(commentId, { status, reason }),

    onSuccess: () => {
      // Invalidate comment lists to refetch with updated data
      queryClient.invalidateQueries({ queryKey: queryKeys.comments.lists() });
    },
  });
}
