import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { AdminTipSettings } from "@/lib/api";

interface TipSettingsState {
  // Data
  settings: AdminTipSettings | null;
  isLoading: boolean;
  error: string | null;

  // Actions
  setSettings: (settings: AdminTipSettings) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  reset: () => void;
}

const initialState = {
  settings: null,
  isLoading: false,
  error: null,
};

export const useTipSettingsStore = create<TipSettingsState>()(
  devtools(
    (set) => ({
      ...initialState,

      setSettings: (settings) =>
        set({ settings, error: null, isLoading: false }),

      setLoading: (isLoading) => set({ isLoading }),

      setError: (error) => set({ error, isLoading: false }),

      reset: () => set(initialState),
    }),
    { name: "tip-settings-store" }
  )
);
