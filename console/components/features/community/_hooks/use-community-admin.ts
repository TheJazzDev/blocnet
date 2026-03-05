"use client";

import { useState } from "react";
import {
  type AdminCommunityComment,
  type AdminCommunityPost,
  type ContentStatus,
} from "@/lib/api-client";
import {
  useCommunityPostsQuery,
  useCommunityCommentsQuery,
  useModerateCommunityPostMutation,
  useModerateCommunityCommentMutation,
} from "@/lib/hooks/queries";
import { useDebounce } from "@/lib/hooks";
import type { StatusFilter, TopicFilter } from "../_lib/community-admin";

const LIMIT = 25;

export function useCommunityAdmin() {
  const [postSearchInput, setPostSearchInput] = useState("");
  const [postStatus, setPostStatus] = useState<StatusFilter>("all");
  const [postTopic, setPostTopic] = useState<TopicFilter>("all");
  const [postOffset, setPostOffset] = useState(0);

  const [commentSearchInput, setCommentSearchInput] = useState("");
  const [commentStatus, setCommentStatus] = useState<StatusFilter>("all");
  const [commentOffset, setCommentOffset] = useState(0);

  const [postDialogOpen, setPostDialogOpen] = useState(false);
  const [selectedPost, setSelectedPost] = useState<AdminCommunityPost | null>(null);
  const [postTargetStatus, setPostTargetStatus] = useState<ContentStatus>("active");

  const [commentDialogOpen, setCommentDialogOpen] = useState(false);
  const [selectedComment, setSelectedComment] = useState<AdminCommunityComment | null>(
    null,
  );
  const [commentTargetStatus, setCommentTargetStatus] = useState<ContentStatus>("active");

  // Debounce search inputs
  const postQ = useDebounce(postSearchInput.trim(), 300);
  const commentQ = useDebounce(commentSearchInput.trim(), 300);

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

  // Mutation hooks
  const moderatePostMutation = useModerateCommunityPostMutation();
  const moderateCommentMutation = useModerateCommunityCommentMutation();

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

    postDialogOpen,
    setPostDialogOpen,
    postTargetStatus,
    commentDialogOpen,
    setCommentDialogOpen,
    commentTargetStatus,
    openPostModeration,
    openCommentModeration,
    submitPostModeration,
    submitCommentModeration,
  };
}
