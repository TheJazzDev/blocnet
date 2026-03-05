"use client";

import { useCallback, useEffect } from "react";
import { useAuditLogStore } from "@/lib/stores/audit-log-store";
import { clientApi } from "@/lib/api-client";

interface UseAuditLogOptions {
  autoLoad?: boolean;
}

/**
 * Hook to manage audit log
 */
export function useAuditLog(options: UseAuditLogOptions = {}) {
  const { autoLoad = true } = options;

  const store = useAuditLogStore();
  const { logs, isLoading, error, limit, setLogs, setLoading, setError } = store;

  const loadLogs = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const data = await clientApi.listAuditLog(limit);
      setLogs(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load audit logs");
    }
  }, [limit, setLogs, setLoading, setError]);

  useEffect(() => {
    if (autoLoad) {
      void loadLogs();
    }
  }, [autoLoad, loadLogs]);

  return {
    ...store,
    loadLogs,
    refresh: loadLogs,
  };
}
