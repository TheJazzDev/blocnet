"use client";

import { useCallback, useEffect } from "react";
import { useQuestSubmissionsStore } from "@/lib/stores/quest-submissions-store";
import { apiFetch } from "@/lib/api-client";
import type { QuestSubmission } from "@/components/features/quest-submissions/_components/types";

interface UseQuestSubmissionsOptions {
  autoLoad?: boolean;
}

/**
 * Hook to manage quest submissions with review functionality
 */
export function useQuestSubmissions(options: UseQuestSubmissionsOptions = {}) {
  const { autoLoad = true } = options;

  const store = useQuestSubmissionsStore();
  const {
    submissions,
    isLoading,
    error,
    statusFilter,
    setSubmissions,
    setLoading,
    setError,
  } = store;

  const loadSubmissions = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (statusFilter !== "all") {
        params.append("status", statusFilter);
      }
      const url = `/admin/quests/submissions${params.toString() ? `?${params.toString()}` : ""}`;
      const data = await apiFetch<QuestSubmission[]>(url);
      setSubmissions(data ?? []);
    } catch (err: unknown) {
      console.error("Error fetching submissions:", err);
      setError(
        err instanceof Error ? err.message : "Failed to load submissions"
      );
    } finally {
      setLoading(false);
    }
  }, [statusFilter, setSubmissions, setLoading, setError]);

  // Auto-load when filter changes
  useEffect(() => {
    if (autoLoad) {
      void loadSubmissions();
    }
  }, [autoLoad, statusFilter, loadSubmissions]);

  return {
    ...store,
    loadSubmissions,
    refresh: loadSubmissions,
  };
}
