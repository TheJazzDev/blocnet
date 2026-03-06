"use client";

import { useState } from "react";
import {
  type AdminCommunityComment,
  type AdminCommunityPost,
  type CommunityModerationReport,
  type CommunityReportStatus,
  type CommunityReportTargetType,
  type ContentStatus,
} from "@/lib/api-client";
import {
  useCommunityReportsQuery,
  useCommunityPostsQuery,
  useCommunityCommentsQuery,
  useReviewCommunityReportMutation,
  useModerateCommunityPostMutation,
  useModerateCommunityCommentMutation,
} from "@/lib/hooks/queries";
import { useDebounce } from "@/lib/hooks";
import type {
  ReportStatusFilter,
  ReportTargetTypeFilter,
  StatusFilter,
  TopicFilter,
} from "../_lib/community-admin";

const LIMIT = 25;

export function useCommunityAdmin() {
  const [postSearchInput, setPostSearchInput] = useState("");
  const [postStatus, setPostStatus] = useState<StatusFilter>("all");
  const [postTopic, setPostTopic] = useState<TopicFilter>("all");
  const [postOffset, setPostOffset] = useState(0);

  const [commentSearchInput, setCommentSearchInput] = useState("");
  const [commentStatus, setCommentStatus] = useState<StatusFilter>("all");
  const [commentOffset, setCommentOffset] = useState(0);

  const [reportSearchInput, setReportSearchInput] = useState("");
  const [reportStatus, setReportStatus] = useState<ReportStatusFilter>("all");
  const [reportTargetType, setReportTargetType] =
    useState<ReportTargetTypeFilter>("all");
  const [reportOffset, setReportOffset] = useState(0);

  const [postDialogOpen, setPostDialogOpen] = useState(false);
  const [selectedPost, setSelectedPost] = useState<AdminCommunityPost | null>(null);
  const [postTargetStatus, setPostTargetStatus] = useState<ContentStatus>("active");

  const [commentDialogOpen, setCommentDialogOpen] = useState(false);
  const [selectedComment, setSelectedComment] = useState<AdminCommunityComment | null>(
    null,
  );
  const [commentTargetStatus, setCommentTargetStatus] = useState<ContentStatus>("active");

  const [reportDialogOpen, setReportDialogOpen] = useState(false);
  const [selectedReport, setSelectedReport] =
    useState<CommunityModerationReport | null>(null);
  const [reportTargetStatus, setReportTargetStatus] =
    useState<Exclude<CommunityReportStatus, "open">>("resolved");

  const [userActionsDialogOpen, setUserActionsDialogOpen] = useState(false);
  const [selectedModerationUserId, setSelectedModerationUserId] = useState<string | null>(
    null,
  );
  const [selectedModerationReportId, setSelectedModerationReportId] = useState<
    string | null
  >(null);

  // Debounce search inputs
  const postQ = useDebounce(postSearchInput.trim(), 300);
  const commentQ = useDebounce(commentSearchInput.trim(), 300);
  const reportQ = useDebounce(reportSearchInput.trim(), 300);

  // TanStack Query hooks
  const {
    data: posts = [],
    isLoading: postsLoading,
    error: postsError,
  } = useCommunityPostsQuery({
    q: postQ || undefined,
    status: postStatus === "all" ? undefined : (postStatus as ContentStatus),
    topic: postTopic === "all" ? undefined : postTopic,
    limit: LIMIT,
    offset: postOffset,
  });

  const {
    data: comments = [],
    isLoading: commentsLoading,
    error: commentsError,
  } = useCommunityCommentsQuery({
    q: commentQ || undefined,
    status: commentStatus === "all" ? undefined : (commentStatus as ContentStatus),
    limit: LIMIT,
    offset: commentOffset,
  });

  const {
    data: reportsResponse,
    isLoading: reportsLoading,
    error: reportsError,
  } = useCommunityReportsQuery({
    q: reportQ || undefined,
    status:
      reportStatus === "all" ? undefined : (reportStatus as CommunityReportStatus),
    targetType:
      reportTargetType === "all"
        ? undefined
        : (reportTargetType as CommunityReportTargetType),
    limit: LIMIT,
    offset: reportOffset,
  });

  const reports = reportsResponse?.data ?? [];
  const reportsTotal = reportsResponse?.total ?? 0;

  // Mutation hooks
  const moderatePostMutation = useModerateCommunityPostMutation();
  const moderateCommentMutation = useModerateCommunityCommentMutation();
  const reviewReportMutation = useReviewCommunityReportMutation();

  function openPostModeration(post: AdminCommunityPost, nextStatus: ContentStatus) {
    setSelectedPost(post);
    setPostTargetStatus(nextStatus);
    setPostDialogOpen(true);
  }

  function openCommentModeration(
    comment: AdminCommunityComment,
    nextStatus: ContentStatus,
  ) {
    setSelectedComment(comment);
    setCommentTargetStatus(nextStatus);
    setCommentDialogOpen(true);
  }

  async function submitPostModeration(nextStatus: ContentStatus, reason: string) {
    if (!selectedPost) return;

    await moderatePostMutation.mutateAsync({
      postId: selectedPost.id,
      status: nextStatus,
      reason,
    });
  }

  async function submitCommentModeration(nextStatus: ContentStatus, reason: string) {
    if (!selectedComment) return;

    await moderateCommentMutation.mutateAsync({
      commentId: selectedComment.id,
      status: nextStatus,
      reason,
    });
  }

  function openReportReview(
    report: CommunityModerationReport,
    nextStatus: Exclude<CommunityReportStatus, "open">,
  ) {
    setSelectedReport(report);
    setReportTargetStatus(nextStatus);
    setReportDialogOpen(true);
  }

  async function submitReportReview(
    nextStatus: Exclude<CommunityReportStatus, "open">,
    note: string,
  ) {
    if (!selectedReport) return;
    await reviewReportMutation.mutateAsync({
      reportId: selectedReport.id,
      status: nextStatus,
      note,
    });
  }

  function openUserActions(
    report: CommunityModerationReport,
    userIdOverride?: string | null,
  ) {
    const userId = userIdOverride ?? report.targetUserId ?? report.targetUser?.id ?? null;
    if (!userId) return;
    setSelectedModerationUserId(userId);
    setSelectedModerationReportId(report.id);
    setUserActionsDialogOpen(true);
  }

  return {
    posts,
    postsLoading,
    postsError: postsError ? (postsError instanceof Error ? postsError.message : "Failed to load posts") : null,
    postSearchInput,
    setPostSearchInput,
    postStatus,
    setPostStatus,
    postTopic,
    setPostTopic,
    postOffset,
    setPostOffset,
    postLimit: LIMIT,

    comments,
    commentsLoading,
    commentsError: commentsError ? (commentsError instanceof Error ? commentsError.message : "Failed to load comments") : null,
    commentSearchInput,
    setCommentSearchInput,
    commentStatus,
    setCommentStatus,
    commentOffset,
    setCommentOffset,
    commentLimit: LIMIT,

    reports,
    reportsTotal,
    reportsLoading,
    reportsError:
      reportsError
        ? reportsError instanceof Error
          ? reportsError.message
          : "Failed to load reports"
        : null,
    reportSearchInput,
    setReportSearchInput,
    reportStatus,
    setReportStatus,
    reportTargetType,
    setReportTargetType,
    reportOffset,
    setReportOffset,
    reportLimit: LIMIT,

    postDialogOpen,
    setPostDialogOpen,
    postTargetStatus,
    commentDialogOpen,
    setCommentDialogOpen,
    commentTargetStatus,
    reportDialogOpen,
    setReportDialogOpen,
    reportTargetStatus,
    userActionsDialogOpen,
    setUserActionsDialogOpen,
    selectedModerationUserId,
    selectedModerationReportId,
    openPostModeration,
    openCommentModeration,
    submitPostModeration,
    submitCommentModeration,
    openReportReview,
    submitReportReview,
    openUserActions,
  };
}
