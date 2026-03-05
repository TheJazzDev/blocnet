import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { AuditLog } from "@/lib/api";

interface AuditLogState {
  // Data
  logs: AuditLog[];
  isLoading: boolean;
  error: string | null;

  // Pagination
  limit: number;

  // Actions
  setLogs: (logs: AuditLog[]) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  setLimit: (limit: number) => void;
  reset: () => void;
}

const initialState = {
  logs: [],
  isLoading: false,
  error: null,
  limit: 100,
};

export const useAuditLogStore = create<AuditLogState>()(
  devtools(
    (set) => ({
      ...initialState,

      setLogs: (logs) => set({ logs, error: null, isLoading: false }),

      setLoading: (isLoading) => set({ isLoading }),

      setError: (error) => set({ error, isLoading: false }),

      setLimit: (limit) => set({ limit }),

      reset: () => set(initialState),
    }),
    { name: "audit-log-store" }
  )
);
