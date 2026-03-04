"use client";

import { useCallback, useEffect } from "react";
import { useRolesStore } from "@/lib/stores";
import { clientApi } from "@/lib/api-client";

interface UseRolesOptions {
  autoLoad?: boolean;
}

/**
 * Hook to manage roles matrix
 */
export function useRoles(options: UseRolesOptions = {}) {
  const { autoLoad = true } = options;
  const { rolesMatrix, isLoading, error, setRolesMatrix, setLoading, setError } =
    useRolesStore();

  const loadRoles = useCallback(async () => {
    if (rolesMatrix) return; // Only load once

    setLoading(true);
    try {
      const data = await clientApi.getRolesMatrix();
      setRolesMatrix(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load roles");
    }
  }, [rolesMatrix, setRolesMatrix, setLoading, setError]);

  useEffect(() => {
    if (autoLoad) {
      void loadRoles();
    }
  }, [autoLoad, loadRoles]);

  return {
    rolesMatrix,
    isLoading,
    error,
    loadRoles,
  };
}
