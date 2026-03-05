import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { AdminTipTransaction, TipDirection } from "@/lib/api-client";

export type DirectionFilter = "all" | Exclude<TipDirection, "all">;

interface TipsTransactionsState {
  // Data
  rows: AdminTipTransaction[];
  total: number;
  isLoading: boolean;
  error: string | null;

  // Filters
  searchInput: string;
  q: string;
  currencyCode: string;
  direction: DirectionFilter;
  limit: number;
  offset: number;

  // Actions - Data
  setRows: (rows: AdminTipTransaction[]) => void;
  setTotal: (total: number) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;

  // Actions - Filters
  setSearchInput: (input: string) => void;
  setQ: (q: string) => void;
  setCurrencyCode: (code: string) => void;
  setDirection: (direction: DirectionFilter) => void;
  setLimit: (limit: number) => void;
  setOffset: (offset: number) => void;

  reset: () => void;
}

const initialState = {
  rows: [],
  total: 0,
  isLoading: true,
  error: null,
  searchInput: "",
  q: "",
  currencyCode: "all",
  direction: "all" as DirectionFilter,
  limit: 25,
  offset: 0,
};

export const useTipsTransactionsStore = create<TipsTransactionsState>()(
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
      setCurrencyCode: (currencyCode) => set({ currencyCode, offset: 0 }),
      setDirection: (direction) => set({ direction, offset: 0 }),
      setLimit: (limit) => set({ limit, offset: 0 }),
      setOffset: (offset) => set({ offset }),

      reset: () => set(initialState),
    }),
    { name: "tips-transactions-store" }
  )
);
