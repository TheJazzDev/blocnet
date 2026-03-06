import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  clientApi,
  type AdminCommunityPost,
  type AdminCommunityComment,
  type ContentStatus,
  type CommunityTopic,
  type CommunityReportStatus,
  type CommunityReportTargetType,
  type CommunityModerationReportsResponse,
  type CommunityModerationUserState,
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

export function useCommunityReportsQuery(params?: {
  q?: string;
  status?: CommunityReportStatus;
  targetType?: CommunityReportTargetType;
  limit?: number;
  offset?: number;
}) {
  return useQuery<CommunityModerationReportsResponse>({
    queryKey: queryKeys.community.moderation.reports(params ?? {}),
    queryFn: () => clientApi.listCommunityReports(params),
    ...queryOptions.standard,
  });
}

export function useReviewCommunityReportMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      reportId,
      status,
      note,
    }: {
      reportId: string;
      status: Exclude<CommunityReportStatus, "open">;
      note?: string;
    }) => clientApi.reviewCommunityReport(reportId, { status, note }),

    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.community.moderation.all });
    },
  });
}

export function useCommunityModerationUserStateQuery(
  userId: string | null,
  options?: { enabled?: boolean },
) {
  const enabled = Boolean(userId) && (options?.enabled ?? true);
  return useQuery<CommunityModerationUserState>({
    queryKey: queryKeys.community.moderation.userState(userId ?? "unknown"),
    queryFn: () => clientApi.getCommunityModerationUserState(userId as string),
    enabled,
    ...queryOptions.standard,
  });
}

export function useIssueCommunityWarningMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      userId,
      reason,
      reportId,
    }: {
      userId: string;
      reason: string;
      reportId?: string;
    }) => clientApi.issueCommunityWarning(userId, { reason, reportId }),
    onSuccess: (data) => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.community.moderation.userState(data.id),
      });
      queryClient.invalidateQueries({ queryKey: queryKeys.community.moderation.all });
    },
  });
}

export function useApplyCommunityMuteMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      userId,
      durationHours,
      reason,
      reportId,
    }: {
      userId: string;
      durationHours: number;
      reason: string;
      reportId?: string;
    }) =>
      clientApi.applyCommunityMute(userId, {
        durationHours,
        reason,
        reportId,
      }),
    onSuccess: (data) => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.community.moderation.userState(data.id),
      });
      queryClient.invalidateQueries({ queryKey: queryKeys.community.moderation.all });
    },
  });
}

export function useApplyCommunitySuspensionMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      userId,
      durationHours,
      reason,
      reportId,
    }: {
      userId: string;
      durationHours: number;
      reason: string;
      reportId?: string;
    }) =>
      clientApi.applyCommunitySuspension(userId, {
        durationHours,
        reason,
        reportId,
      }),
    onSuccess: (data) => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.community.moderation.userState(data.id),
      });
      queryClient.invalidateQueries({ queryKey: queryKeys.community.moderation.all });
    },
  });
}

export function useApplyCommunityRestrictionsMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      userId,
      postingHours,
      commentingHours,
      reason,
      reportId,
    }: {
      userId: string;
      postingHours?: number;
      commentingHours?: number;
      reason: string;
      reportId?: string;
    }) =>
      clientApi.applyCommunityRestrictions(userId, {
        postingHours,
        commentingHours,
        reason,
        reportId,
      }),
    onSuccess: (data) => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.community.moderation.userState(data.id),
      });
      queryClient.invalidateQueries({ queryKey: queryKeys.community.moderation.all });
    },
  });
}

export function useClearCommunityRestrictionsMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      userId,
      reason,
      reportId,
    }: {
      userId: string;
      reason: string;
      reportId?: string;
    }) => clientApi.clearCommunityRestrictions(userId, { reason, reportId }),
    onSuccess: (data) => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.community.moderation.userState(data.id),
      });
      queryClient.invalidateQueries({ queryKey: queryKeys.community.moderation.all });
    },
  });
}
