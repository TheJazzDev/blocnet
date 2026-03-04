"use client";

import { useCallback, useEffect } from "react";
import { useQuestsStore } from "@/lib/stores/quests-store";
import { apiFetch } from "@/lib/api-client";
import type { QuestModel, BadgeOption } from "@/components/features/quests/_components/quest-models";

interface UseQuestsOptions {
  autoLoad?: boolean;
}

/**
 * Hook to manage quests with create/edit functionality
 */
export function useQuests(options: UseQuestsOptions = {}) {
  const { autoLoad = true } = options;

  const store = useQuestsStore();
  const {
    quests,
    badges,
    isLoading,
    error,
    setQuests,
    setBadges,
    setLoading,
    setError,
  } = store;

  const loadData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [questsData, badgesData] = await Promise.all([
        apiFetch<QuestModel[]>("/admin/quests"),
        apiFetch<BadgeOption[]>("/admin/badges"),
      ]);
      setQuests(questsData ?? []);
      setBadges(badgesData ?? []);
    } catch (err: unknown) {
      console.error("Error fetching quests admin data:", err);
      setError(err instanceof Error ? err.message : "Failed to load quests");
    } finally {
      setLoading(false);
    }
  }, [setQuests, setBadges, setLoading, setError]);

  // Auto-load on mount
  useEffect(() => {
    if (autoLoad) {
      void loadData();
    }
  }, [autoLoad, loadData]);

  return {
    ...store,
    loadData,
    refresh: loadData,
  };
}
