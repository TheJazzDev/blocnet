"use client";

import { useCallback, useEffect } from "react";
import { useUpdatesStore } from "@/lib/stores/updates-store";
import { clientApi } from "@/lib/api-client";

interface UseUpdatesOptions {
  autoLoad?: boolean;
}

/**
 * Hook to manage updates list with filters
 */
export function useUpdates(options: UseUpdatesOptions = {}) {
  const { autoLoad = true } = options;

  const store = useUpdatesStore();
  const {
    updates,
    isLoading,
    error,
    searchQuery,
    statusFilter,
    projectIdFilter,
    authorIdFilter,
    setUpdates,
    setLoading,
    setError,
  } = store;

  const loadUpdates = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const data = await clientApi.listAdminUpdates({
        q: searchQuery || undefined,
        status: statusFilter === "all" ? undefined : statusFilter || undefined,
        projectId: projectIdFilter || undefined,
        authorId: authorIdFilter || undefined,
      });

      setUpdates(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load updates");
    }
  }, [
    searchQuery,
    statusFilter,
    projectIdFilter,
    authorIdFilter,
    setUpdates,
    setLoading,
    setError,
  ]);

  useEffect(() => {
    if (autoLoad) {
      void loadUpdates();
    }
  }, [autoLoad, loadUpdates]);

  return {
    ...store,
    loadUpdates,
    refresh: loadUpdates,
  };
}
