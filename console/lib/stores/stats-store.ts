import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { AdminStats } from "@/lib/api";

interface StatsState {
  stats: AdminStats | null;
  isLoading: boolean;
  error: string | null;
  lastFetched: number | null;

  // Actions
  setStats: (stats: AdminStats) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  clearStats: () => void;

  // Computed
  shouldRefresh: (maxAgeMs?: number) => boolean;
}

export const useStatsStore = create<StatsState>()(
  devtools(
    (set, get) => ({
      stats: null,
      isLoading: false,
      error: null,
      lastFetched: null,

      setStats: (stats) =>
        set({ stats, lastFetched: Date.now(), error: null, isLoading: false }),

      setLoading: (isLoading) => set({ isLoading }),

      setError: (error) => set({ error, isLoading: false }),

      clearStats: () =>
        set({ stats: null, isLoading: false, error: null, lastFetched: null }),

      shouldRefresh: (maxAgeMs = 60000) => {
        const { lastFetched } = get();
        if (!lastFetched) return true;
        return Date.now() - lastFetched > maxAgeMs;
      },
    }),
    { name: "stats-store" }
  )
);
