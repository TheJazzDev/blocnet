"use client";

import { useCallback, useEffect } from "react";
import { useWalletWithdrawalsStore } from "@/lib/stores/wallet-withdrawals-store";
import { clientApi } from "@/lib/api-client";

interface UseWalletWithdrawalsOptions {
  autoLoad?: boolean;
}

/**
 * Hook to manage wallet withdrawals with filters and review
 */
export function useWalletWithdrawals(options: UseWalletWithdrawalsOptions = {}) {
  const { autoLoad = true } = options;

  const store = useWalletWithdrawalsStore();
  const {
    rows,
    total,
    isLoading,
    error,
    searchInput,
    q,
    status,
    limit,
    offset,
    setRows,
    setTotal,
    setLoading,
    setError,
    setQ,
  } = store;

  const loadWithdrawals = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await clientApi.listWalletWithdrawals({
        q,
        status: status === "all" ? undefined : status,
        limit,
        offset,
      });
      setRows(result.data);
      setTotal(result.total);
    } catch (e: unknown) {
      setRows([]);
      setTotal(0);
      setError(e instanceof Error ? e.message : "Failed to load withdrawals");
    } finally {
      setLoading(false);
    }
  }, [q, status, limit, offset, setRows, setTotal, setLoading, setError]);

  // Debounce search input
  useEffect(() => {
    const timer = setTimeout(() => {
      setQ(searchInput.trim());
      store.setOffset(0);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchInput, setQ, store]);

  // Auto-load when filters change
  useEffect(() => {
    if (autoLoad) {
      void loadWithdrawals();
    }
  }, [autoLoad, loadWithdrawals]);

  return {
    ...store,
    loadWithdrawals,
    refresh: loadWithdrawals,
  };
}
