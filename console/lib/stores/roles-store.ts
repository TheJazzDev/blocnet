import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { RolesMatrixResponse } from "@/lib/api";

interface RolesState {
  rolesMatrix: RolesMatrixResponse | null;
  isLoading: boolean;
  error: string | null;

  // Actions
  setRolesMatrix: (matrix: RolesMatrixResponse) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  clearRoles: () => void;
}

export const useRolesStore = create<RolesState>()(
  devtools(
    (set) => ({
      rolesMatrix: null,
      isLoading: false,
      error: null,

      setRolesMatrix: (rolesMatrix) =>
        set({ rolesMatrix, error: null, isLoading: false }),

      setLoading: (isLoading) => set({ isLoading }),

      setError: (error) => set({ error, isLoading: false }),

      clearRoles: () =>
        set({ rolesMatrix: null, isLoading: false, error: null }),
    }),
    { name: "roles-store" }
  )
);
