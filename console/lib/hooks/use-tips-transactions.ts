"use client";

import { useCallback, useEffect } from "react";
import { useTipsTransactionsStore } from "@/lib/stores/tips-transactions-store";
import { clientApi } from "@/lib/api-client";

interface UseTipsTransactionsOptions {
  autoLoad?: boolean;
}

/**
 * Hook to manage tip transactions with filters
 */
export function useTipsTransactions(options: UseTipsTransactionsOptions = {}) {
  const { autoLoad = true } = options;

  const store = useTipsTransactionsStore();
  const {
    rows,
    total,
    isLoading,
    error,
    searchInput,
    q,
    currencyCode,
    direction,
    limit,
    offset,
    setRows,
    setTotal,
    setLoading,
    setError,
    setQ,
  } = store;

  const loadTransactions = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await clientApi.listTipTransactions({
        q,
        currencyCode: currencyCode === "all" ? undefined : currencyCode,
        direction: direction === "all" ? undefined : direction,
        limit,
        offset,
      });
      setRows(result.data);
      setTotal(result.total);
    } catch (e: unknown) {
      setRows([]);
      setTotal(0);
      setError(e instanceof Error ? e.message : "Failed to load tip transactions");
    } finally {
      setLoading(false);
    }
  }, [q, currencyCode, direction, limit, offset, setRows, setTotal, setLoading, setError]);

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
      void loadTransactions();
    }
  }, [autoLoad, loadTransactions]);

  return {
    ...store,
    loadTransactions,
    refresh: loadTransactions,
  };
}
