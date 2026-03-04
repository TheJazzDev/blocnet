"use client";

import { useCallback, useEffect } from "react";
import { useUsersStore } from "@/lib/stores/users-store";
import { clientApi } from "@/lib/api-client";

interface UseUsersOptions {
  autoLoad?: boolean;
}

/**
 * Hook to manage users list with filters and pagination
 */
export function useUsers(options: UseUsersOptions = {}) {
  const { autoLoad = true } = options;

  const store = useUsersStore();
  const {
    users,
    total,
    isLoading,
    error,
    page,
    limit,
    searchQuery,
    roleFilter,
    statusFilter,
    setUsers,
    setLoading,
    setError,
    offset,
  } = store;

  const loadUsers = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const data = await clientApi.listUsers({
        offset: offset(),
        limit,
        q: searchQuery || undefined,
        role: roleFilter || undefined,
        status: statusFilter === "all" ? undefined : statusFilter || undefined,
      });

      setUsers(data.data, data.total);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load users");
    }
  }, [
    offset,
    limit,
    searchQuery,
    roleFilter,
    statusFilter,
    setUsers,
    setLoading,
    setError,
  ]);

  // Auto-load users when filters change
  useEffect(() => {
    if (autoLoad) {
      void loadUsers();
    }
  }, [autoLoad, loadUsers]);

  return {
    ...store,
    loadUsers,
    refresh: loadUsers,
  };
}
