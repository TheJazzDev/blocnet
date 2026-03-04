"use client";

import { useEffect } from "react";
import { useAuthStore } from "@/lib/stores";
import { clientApi } from "@/lib/api-client";

/**
 * Hook to initialize and sync auth state from the server
 * Call this once at the app root level
 */
export function useAuthInit() {
  const { setUser, setLoading, setError, user } = useAuthStore();

  useEffect(() => {
    async function loadUser() {
      // Only load if we haven't loaded yet
      if (user !== null) return;

      setLoading(true);
      try {
        const me = await clientApi.getMe();
        setUser(me);
      } catch (error) {
        setError(error instanceof Error ? error.message : "Failed to load user");
        setUser(null);
      } finally {
        setLoading(false);
      }
    }

    void loadUser();
  }, []); // Only run once on mount

  return useAuthStore();
}
