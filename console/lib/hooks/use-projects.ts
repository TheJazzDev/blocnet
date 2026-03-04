"use client";

import { useCallback, useEffect } from "react";
import { useProjectsStore } from "@/lib/stores/projects-store";
import { clientApi } from "@/lib/api-client";

interface UseProjectsOptions {
  autoLoad?: boolean;
}

/**
 * Hook to manage projects list with filters
 */
export function useProjects(options: UseProjectsOptions = {}) {
  const { autoLoad = true } = options;

  const store = useProjectsStore();
  const {
    projects,
    isLoading,
    error,
    searchQuery,
    statusFilter,
    setProjects,
    setLoading,
    setError,
  } = store;

  const loadProjects = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const data = await clientApi.listAdminProjects({
        q: searchQuery || undefined,
        status: statusFilter === "all" ? undefined : statusFilter || undefined,
      });

      setProjects(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load projects");
    }
  }, [searchQuery, statusFilter, setProjects, setLoading, setError]);

  useEffect(() => {
    if (autoLoad) {
      void loadProjects();
    }
  }, [autoLoad, loadProjects]);

  return {
    ...store,
    loadProjects,
    refresh: loadProjects,
  };
}
