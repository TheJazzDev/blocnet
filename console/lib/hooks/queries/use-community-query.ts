import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  clientApi,
  type AdminCommunityPost,
  type AdminCommunityComment,
  type ContentStatus,
  type CommunityTopic,
} from "@/lib/api-client";
import { queryKeys } from "./query-keys";
import { queryOptions } from "./query-options";

/**
 * Query hook for listing community posts with filters
 */
export function useCommunityPostsQuery(params?: {
  q?: string;
  status?: ContentStatus;
  topic?: CommunityTopic;
  authorId?: string;
  limit?: number;
  offset?: number;
}) {
  return useQuery({
    queryKey: [...queryKeys.community.posts.lists(), params ?? {}],
    queryFn: () => clientApi.listAdminCommunityPosts(params),
    ...queryOptions.standard,
  });
}

/**
 * Query hook for listing community comments with filters
 */
export function useCommunityCommentsQuery(params?: {
  q?: string;
  status?: ContentStatus;
  postId?: string;
  authorId?: string;
  limit?: number;
  offset?: number;
}) {
  return useQuery({
    queryKey: [...queryKeys.community.comments.lists(), params ?? {}],
    queryFn: () => clientApi.listAdminCommunityComments(params),
    ...queryOptions.standard,
  });
}

/**
 * Mutation hook for moderating community post status
 */
export function useModerateCommunityPostMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      postId,
      status,
      reason,
    }: {
      postId: string;
      status: ContentStatus;
      reason: string;
    }) => clientApi.moderateCommunityPostStatus(postId, { status, reason }),

    onSuccess: () => {
      // Invalidate community posts lists to refetch
      queryClient.invalidateQueries({ queryKey: queryKeys.community.posts.all });
    },
  });
}

/**
 * Mutation hook for moderating community comment status
 */
export function useModerateCommunityCommentMutation() {
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
    }) => clientApi.moderateCommunityCommentStatus(commentId, { status, reason }),

    onSuccess: () => {
      // Invalidate community comments lists to refetch
      queryClient.invalidateQueries({ queryKey: queryKeys.community.comments.all });
    },
  });
}
