import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { AdminUser } from "@/lib/api-client";
import type {
  GovernanceAction,
  GovernanceFilter,
  PendingGovernanceAction,
  StatusFilter,
} from "@/components/features/admin-access/_components/admin-access-types";

interface AdminAccessState {
  // Data
  users: AdminUser[];
  total: number;
  isLoading: boolean;
  error: string | null;

  // Filters
  searchInput: string;
  q: string;
  role: GovernanceFilter;
  status: StatusFilter;
  limit: number;
  offset: number;

  // Action state
  actionUserId: string | null;

  // Confirm dialog
  confirmOpen: boolean;
  confirmError: string | null;
  confirmNote: string;
  pendingAction: PendingGovernanceAction;

  // Actions - Data
  setUsers: (users: AdminUser[]) => void;
  setTotal: (total: number) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;

  // Actions - Filters
  setSearchInput: (input: string) => void;
  setQ: (q: string) => void;
  setRole: (role: GovernanceFilter) => void;
  setStatus: (status: StatusFilter) => void;
  setLimit: (limit: number) => void;
  setOffset: (offset: number) => void;

  // Actions - Action state
  setActionUserId: (id: string | null) => void;

  // Actions - Confirm dialog
  openConfirmDialog: (user: AdminUser, action: GovernanceAction) => void;
  closeConfirmDialog: () => void;
  setConfirmError: (error: string | null) => void;
  setConfirmNote: (note: string) => void;

  reset: () => void;
}

const initialState = {
  users: [],
  total: 0,
  isLoading: false,
  error: null,
  searchInput: "",
  q: "",
  role: "all" as GovernanceFilter,
  status: "active" as StatusFilter,
  limit: 25,
  offset: 0,
  actionUserId: null,
  confirmOpen: false,
  confirmError: null,
  confirmNote: "",
  pendingAction: null,
};

export const useAdminAccessStore = create<AdminAccessState>()(
  devtools(
    (set) => ({
      ...initialState,

      // Data actions
      setUsers: (users) => set({ users }),
      setTotal: (total) => set({ total }),
      setLoading: (isLoading) => set({ isLoading }),
      setError: (error) => set({ error, isLoading: false }),

      // Filter actions
      setSearchInput: (searchInput) => set({ searchInput }),
      setQ: (q) => set({ q }),
      setRole: (role) => set({ role, offset: 0 }),
      setStatus: (status) => set({ status, offset: 0 }),
      setLimit: (limit) => set({ limit, offset: 0 }),
      setOffset: (offset) => set({ offset }),

      // Action state
      setActionUserId: (actionUserId) => set({ actionUserId }),

      // Confirm dialog actions
      openConfirmDialog: (user, action) =>
        set({
          pendingAction: { user, action },
          confirmError: null,
          confirmNote: "",
          confirmOpen: true,
        }),
      closeConfirmDialog: () =>
        set({
          confirmOpen: false,
          pendingAction: null,
          confirmNote: "",
        }),
      setConfirmError: (confirmError) => set({ confirmError }),
      setConfirmNote: (confirmNote) => set({ confirmNote }),

      reset: () => set(initialState),
    }),
    { name: "admin-access-store" }
  )
);
