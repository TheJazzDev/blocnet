import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { AdminUpdate, UpdateStatus } from "@/lib/api";

interface UpdatesState {
  // Data
  updates: AdminUpdate[];
  isLoading: boolean;
  error: string | null;

  // Filters
  searchQuery: string;
  statusFilter: UpdateStatus | "all" | null;
  projectIdFilter: string | null;
  authorIdFilter: string | null;

  // Actions
  setUpdates: (updates: AdminUpdate[]) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  setSearchQuery: (query: string) => void;
  setStatusFilter: (status: UpdateStatus | "all" | null) => void;
  setProjectIdFilter: (projectId: string | null) => void;
  setAuthorIdFilter: (authorId: string | null) => void;
  clearFilters: () => void;
  reset: () => void;

  // Computed
  hasFilters: () => boolean;
}

const initialState = {
  updates: [],
  isLoading: false,
  error: null,
  searchQuery: "",
  statusFilter: null,
  projectIdFilter: null,
  authorIdFilter: null,
};

export const useUpdatesStore = create<UpdatesState>()(
  devtools(
    (set, get) => ({
      ...initialState,

      setUpdates: (updates) =>
        set({ updates, error: null, isLoading: false }),

      setLoading: (isLoading) => set({ isLoading }),

      setError: (error) => set({ error, isLoading: false }),

      setSearchQuery: (searchQuery) => set({ searchQuery }),

      setStatusFilter: (statusFilter) => set({ statusFilter }),

      setProjectIdFilter: (projectIdFilter) => set({ projectIdFilter }),

      setAuthorIdFilter: (authorIdFilter) => set({ authorIdFilter }),

      clearFilters: () =>
        set({
          searchQuery: "",
          statusFilter: null,
          projectIdFilter: null,
          authorIdFilter: null,
        }),

      reset: () => set(initialState),

      hasFilters: () => {
        const { searchQuery, statusFilter, projectIdFilter, authorIdFilter } = get();
        return (
          searchQuery !== "" ||
          (statusFilter !== null && statusFilter !== "all") ||
          projectIdFilter !== null ||
          authorIdFilter !== null
        );
      },
    }),
    { name: "updates-store" }
  )
);
