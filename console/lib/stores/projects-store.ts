import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { AdminProject, ProjectStatus } from "@/lib/api";

interface ProjectsState {
  // Data
  projects: AdminProject[];
  isLoading: boolean;
  error: string | null;

  // Filters
  searchQuery: string;
  statusFilter: ProjectStatus | "all" | null;

  // UI State: "Manage hunters" sheet
  hunterSheetProject: AdminProject | null;

  // Actions
  openHunterSheet: (project: AdminProject) => void;
  closeHunterSheet: () => void;
  setProjects: (projects: AdminProject[]) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  setSearchQuery: (query: string) => void;
  setStatusFilter: (status: ProjectStatus | "all" | null) => void;
  clearFilters: () => void;
  reset: () => void;

  // Computed
  hasFilters: () => boolean;
}

const initialState = {
  projects: [],
  isLoading: false,
  error: null,
  searchQuery: "",
  statusFilter: null,
  hunterSheetProject: null,
};

export const useProjectsStore = create<ProjectsState>()(
  devtools(
    (set, get) => ({
      ...initialState,

      openHunterSheet: (hunterSheetProject) => set({ hunterSheetProject }),

      closeHunterSheet: () => set({ hunterSheetProject: null }),

      setProjects: (projects) =>
        set({ projects, error: null, isLoading: false }),

      setLoading: (isLoading) => set({ isLoading }),

      setError: (error) => set({ error, isLoading: false }),

      setSearchQuery: (searchQuery) => set({ searchQuery }),

      setStatusFilter: (statusFilter) => set({ statusFilter }),

      clearFilters: () =>
        set({
          searchQuery: "",
          statusFilter: null,
        }),

      reset: () => set(initialState),

      hasFilters: () => {
        const { searchQuery, statusFilter } = get();
        return (
          searchQuery !== "" ||
          (statusFilter !== null && statusFilter !== "all")
        );
      },
    }),
    { name: "projects-store" }
  )
);
