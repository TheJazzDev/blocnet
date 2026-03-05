import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { AdminMe } from "@/lib/api";

interface AuthState {
  user: AdminMe | null;
  isLoading: boolean;
  error: string | null;

  // Actions
  setUser: (user: AdminMe | null) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  clearAuth: () => void;

  // Computed
  hasRole: (role: string) => boolean;
  hasAnyRole: (roles: string[]) => boolean;
  hasAllRoles: (roles: string[]) => boolean;
}

export const useAuthStore = create<AuthState>()(
  devtools(
    (set, get) => ({
      user: null,
      isLoading: false,
      error: null,

      setUser: (user) => set({ user, error: null }),

      setLoading: (isLoading) => set({ isLoading }),

      setError: (error) => set({ error, isLoading: false }),

      clearAuth: () => set({ user: null, isLoading: false, error: null }),

      hasRole: (role) => {
        const { user } = get();
        return user?.roles.includes(role) ?? false;
      },

      hasAnyRole: (roles) => {
        const { user } = get();
        if (!user) return false;
        return roles.some((role) => user.roles.includes(role));
      },

      hasAllRoles: (roles) => {
        const { user } = get();
        if (!user) return false;
        return roles.every((role) => user.roles.includes(role));
      },
    }),
    { name: "auth-store" }
  )
);
