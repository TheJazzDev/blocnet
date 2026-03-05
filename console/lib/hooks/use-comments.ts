"use client";

import { useCallback, useEffect } from "react";
import { useCommentsStore } from "@/lib/stores/comments-store";
import { clientApi } from "@/lib/api-client";

interface UseCommentsOptions {
  autoLoad?: boolean;
}

/**
 * Hook to manage comments list with filters
 */
export function useComments(options: UseCommentsOptions = {}) {
  const { autoLoad = true } = options;

  const store = useCommentsStore();
  const {
    comments,
    isLoading,
    error,
    searchQuery,
    statusFilter,
    updateIdFilter,
    authorIdFilter,
    setComments,
    setLoading,
    setError,
  } = store;

  const loadComments = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const data = await clientApi.listAdminComments({
        q: searchQuery || undefined,
        status: statusFilter === "all" ? undefined : statusFilter || undefined,
        updateId: updateIdFilter || undefined,
        authorId: authorIdFilter || undefined,
      });

      setComments(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load comments");
    }
  }, [
    searchQuery,
    statusFilter,
    updateIdFilter,
    authorIdFilter,
    setComments,
    setLoading,
    setError,
  ]);

  useEffect(() => {
    if (autoLoad) {
      void loadComments();
    }
  }, [autoLoad, loadComments]);

  return {
    ...store,
    loadComments,
    refresh: loadComments,
  };
}
