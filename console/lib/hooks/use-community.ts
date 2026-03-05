"use client";

import { useCallback, useEffect } from "react";
import { useCommunityStore } from "@/lib/stores/community-store";
import { clientApi } from "@/lib/api-client";

interface UseCommunityOptions {
  autoLoad?: boolean;
  loadPosts?: boolean;
  loadComments?: boolean;
}

/**
 * Hook to manage community posts and comments
 */
export function useCommunity(options: UseCommunityOptions = {}) {
  const { autoLoad = true, loadPosts = true, loadComments = false } = options;

  const store = useCommunityStore();
  const {
    postSearchQuery,
    postStatusFilter,
    postTopicFilter,
    commentSearchQuery,
    commentStatusFilter,
    commentPostIdFilter,
    setPosts,
    setPostsLoading,
    setPostsError,
    setComments,
    setCommentsLoading,
    setCommentsError,
  } = store;

  const loadCommunityPosts = useCallback(async () => {
    setPostsLoading(true);
    setPostsError(null);

    try {
      const data = await clientApi.listAdminCommunityPosts({
        q: postSearchQuery || undefined,
        status:
          postStatusFilter === "all" ? undefined : postStatusFilter || undefined,
        topic:
          postTopicFilter === "all" ? undefined : postTopicFilter || undefined,
      });

      setPosts(data);
    } catch (err) {
      setPostsError(
        err instanceof Error ? err.message : "Failed to load community posts"
      );
    }
  }, [
    postSearchQuery,
    postStatusFilter,
    postTopicFilter,
    setPosts,
    setPostsLoading,
    setPostsError,
  ]);

  const loadCommunityComments = useCallback(async () => {
    setCommentsLoading(true);
    setCommentsError(null);

    try {
      const data = await clientApi.listAdminCommunityComments({
        q: commentSearchQuery || undefined,
        status:
          commentStatusFilter === "all"
            ? undefined
            : commentStatusFilter || undefined,
        postId: commentPostIdFilter || undefined,
      });

      setComments(data);
    } catch (err) {
      setCommentsError(
        err instanceof Error ? err.message : "Failed to load community comments"
      );
    }
  }, [
    commentSearchQuery,
    commentStatusFilter,
    commentPostIdFilter,
    setComments,
    setCommentsLoading,
    setCommentsError,
  ]);

  useEffect(() => {
    if (autoLoad && loadPosts) {
      void loadCommunityPosts();
    }
  }, [autoLoad, loadPosts, loadCommunityPosts]);

  useEffect(() => {
    if (autoLoad && loadComments) {
      void loadCommunityComments();
    }
  }, [autoLoad, loadComments, loadCommunityComments]);

  return {
    ...store,
    loadCommunityPosts,
    loadCommunityComments,
    refreshPosts: loadCommunityPosts,
    refreshComments: loadCommunityComments,
  };
}
