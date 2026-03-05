"use client";

import { useEffect, useMemo, useState } from "react";
import {
  type OpsEvent,
  type OpsEventProvider,
  type OpsEventSource,
  type OpsEventStatus,
} from "@/lib/api-client";
import { PAGE_SIZE, providerDashboardLink } from "../_lib/ops-events";
import { useOpsEventsQuery } from "@/lib/hooks/queries";

export function useOpsEvents(canView: boolean) {
  const [q, setQ] = useState("");
  const [source, setSource] = useState<"all" | OpsEventSource>("all");
  const [provider, setProvider] = useState<"all" | OpsEventProvider>("all");
  const [status, setStatus] = useState<"all" | OpsEventStatus>("all");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [page, setPage] = useState(0);
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [selectedEvent, setSelectedEvent] = useState<OpsEvent | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  const offset = page * PAGE_SIZE;

  // TanStack Query hook with auto-refresh
  const {
    data: events = [],
    isLoading: loading,
    error: queryError,
    refetch,
  } = useOpsEventsQuery(
    {
      q: q.trim() || undefined,
      source: source === "all" ? undefined : source,
      provider: provider === "all" ? undefined : provider,
      status: status === "all" ? undefined : status,
      from: from.trim() || undefined,
      to: to.trim() || undefined,
      limit: PAGE_SIZE,
      offset,
    },
    { refetchInterval: autoRefresh ? 15000 : false, enabled: canView },
  );

  const error = queryError instanceof Error ? queryError.message : null;
  const hasNext = events.length === PAGE_SIZE;

  useEffect(() => {
    setPage(0);
  }, [from, provider, source, status, to]);

  async function loadEvents(withSpinner: boolean) {
    if (!withSpinner) {
      setRefreshing(true);
    }
    await refetch();
    setRefreshing(false);
  }

  const providerLinks = useMemo(() => {
    const unique = new Map<OpsEventProvider, { label: string; href: string }>();
    for (const event of events) {
      if (unique.has(event.provider)) continue;
      const link = providerDashboardLink(event.provider);
      if (link) unique.set(event.provider, link);
    }
    return [...unique.values()];
  }, [events]);

  async function applyFilters() {
    setPage(0);
    await loadEvents(false);
  }

  function resetFilters() {
    setQ("");
    setSource("all");
    setProvider("all");
    setStatus("all");
    setFrom("");
    setTo("");
    setPage(0);
  }

  return {
    events,
    loading,
    refreshing,
    error,
    q,
    setQ,
    source,
    setSource,
    provider,
    setProvider,
    status,
    setStatus,
    from,
    setFrom,
    to,
    setTo,
    page,
    setPage,
    hasNext,
    autoRefresh,
    setAutoRefresh,
    selectedEvent,
    setSelectedEvent,
    providerLinks,
    loadEvents,
    applyFilters,
    resetFilters,
  };
}
