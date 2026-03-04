import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { AdminComment, ContentStatus } from "@/lib/api";

interface CommentsState {
  // Data
  comments: AdminComment[];
  isLoading: boolean;
  error: string | null;

  // Filters
  searchQuery: string;
  statusFilter: ContentStatus | "all" | null;
  updateIdFilter: string | null;
  authorIdFilter: string | null;

  // Actions
  setComments: (comments: AdminComment[]) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  setSearchQuery: (query: string) => void;
  setStatusFilter: (status: ContentStatus | "all" | null) => void;
  setUpdateIdFilter: (updateId: string | null) => void;
  setAuthorIdFilter: (authorId: string | null) => void;
  clearFilters: () => void;
  reset: () => void;

  // Computed
  hasFilters: () => boolean;
}

const initialState = {
  comments: [],
  isLoading: false,
  error: null,
  searchQuery: "",
  statusFilter: null,
  updateIdFilter: null,
  authorIdFilter: null,
};

export const useCommentsStore = create<CommentsState>()(
  devtools(
    (set, get) => ({
      ...initialState,

      setComments: (comments) =>
        set({ comments, error: null, isLoading: false }),

      setLoading: (isLoading) => set({ isLoading }),

      setError: (error) => set({ error, isLoading: false }),

      setSearchQuery: (searchQuery) => set({ searchQuery }),

      setStatusFilter: (statusFilter) => set({ statusFilter }),

      setUpdateIdFilter: (updateIdFilter) => set({ updateIdFilter }),

      setAuthorIdFilter: (authorIdFilter) => set({ authorIdFilter }),

      clearFilters: () =>
        set({
          searchQuery: "",
          statusFilter: null,
          updateIdFilter: null,
          authorIdFilter: null,
        }),

      reset: () => set(initialState),

      hasFilters: () => {
        const { searchQuery, statusFilter, updateIdFilter, authorIdFilter } = get();
        return (
          searchQuery !== "" ||
          (statusFilter !== null && statusFilter !== "all") ||
          updateIdFilter !== null ||
          authorIdFilter !== null
        );
      },
    }),
    { name: "comments-store" }
  )
);
