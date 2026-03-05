import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { AdminUser, AdminUserStatus } from "@/lib/api";

interface UsersState {
  // Data
  users: AdminUser[];
  total: number;
  isLoading: boolean;
  error: string | null;

  // Pagination
  page: number;
  limit: number;

  // Filters
  searchQuery: string;
  roleFilter: string | null;
  statusFilter: AdminUserStatus | "all" | null;

  // Actions
  setUsers: (users: AdminUser[], total: number) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  setPage: (page: number) => void;
  setLimit: (limit: number) => void;
  setSearchQuery: (query: string) => void;
  setRoleFilter: (role: string | null) => void;
  setStatusFilter: (status: AdminUserStatus | "all" | null) => void;
  clearFilters: () => void;
  reset: () => void;

  // Computed
  hasFilters: () => boolean;
  offset: () => number;
}

const initialState = {
  users: [],
  total: 0,
  isLoading: false,
  error: null,
  page: 0,
  limit: 20,
  searchQuery: "",
  roleFilter: null,
  statusFilter: null,
};

export const useUsersStore = create<UsersState>()(
  devtools(
    (set, get) => ({
      ...initialState,

      setUsers: (users, total) =>
        set({ users, total, error: null, isLoading: false }),

      setLoading: (isLoading) => set({ isLoading }),

      setError: (error) => set({ error, isLoading: false }),

      setPage: (page) => set({ page }),

      setLimit: (limit) => set({ limit, page: 0 }),

      setSearchQuery: (searchQuery) => set({ searchQuery, page: 0 }),

      setRoleFilter: (roleFilter) => set({ roleFilter, page: 0 }),

      setStatusFilter: (statusFilter) => set({ statusFilter, page: 0 }),

      clearFilters: () =>
        set({
          searchQuery: "",
          roleFilter: null,
          statusFilter: null,
          page: 0,
        }),

      reset: () => set(initialState),

      hasFilters: () => {
        const { searchQuery, roleFilter, statusFilter } = get();
        return (
          searchQuery !== "" ||
          roleFilter !== null ||
          (statusFilter !== null && statusFilter !== "all")
        );
      },

      offset: () => {
        const { page, limit } = get();
        return page * limit;
      },
    }),
    { name: "users-store" }
  )
);
