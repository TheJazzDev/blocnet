import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { AdminWalletWithdrawal, WalletWithdrawalStatus } from "@/lib/api-client";

export type StatusFilter = "all" | WalletWithdrawalStatus;

interface WalletWithdrawalsState {
  // Data
  rows: AdminWalletWithdrawal[];
  total: number;
  isLoading: boolean;
  error: string | null;

  // Filters
  searchInput: string;
  q: string;
  status: StatusFilter;
  limit: number;
  offset: number;

  // Dialog
  dialogOpen: boolean;
  selected: AdminWalletWithdrawal | null;
  targetStatus: "approved" | "rejected";

  // Actions - Data
  setRows: (rows: AdminWalletWithdrawal[]) => void;
  setTotal: (total: number) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;

  // Actions - Filters
  setSearchInput: (input: string) => void;
  setQ: (q: string) => void;
  setStatus: (status: StatusFilter) => void;
  setLimit: (limit: number) => void;
  setOffset: (offset: number) => void;

  // Actions - Dialog
  openReviewDialog: (row: AdminWalletWithdrawal, status: "approved" | "rejected") => void;
  closeDialog: () => void;

  reset: () => void;
}

const initialState = {
  rows: [],
  total: 0,
  isLoading: true,
  error: null,
  searchInput: "",
  q: "",
  status: "all" as StatusFilter,
  limit: 25,
  offset: 0,
  dialogOpen: false,
  selected: null,
  targetStatus: "approved" as "approved" | "rejected",
};

export const useWalletWithdrawalsStore = create<WalletWithdrawalsState>()(
  devtools(
    (set) => ({
      ...initialState,

      // Data actions
      setRows: (rows) => set({ rows }),
      setTotal: (total) => set({ total }),
      setLoading: (isLoading) => set({ isLoading }),
      setError: (error) => set({ error, isLoading: false }),

      // Filter actions
      setSearchInput: (searchInput) => set({ searchInput }),
      setQ: (q) => set({ q }),
      setStatus: (status) => set({ status, offset: 0 }),
      setLimit: (limit) => set({ limit, offset: 0 }),
      setOffset: (offset) => set({ offset }),

      // Dialog actions
      openReviewDialog: (row, status) =>
        set({
          selected: row,
          targetStatus: status,
          dialogOpen: true,
        }),
      closeDialog: () =>
        set({
          dialogOpen: false,
        }),

      reset: () => set(initialState),
    }),
    { name: "wallet-withdrawals-store" }
  )
);
