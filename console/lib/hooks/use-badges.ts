"use client";

import { useCallback, useEffect } from "react";
import { useBadgesStore } from "@/lib/stores/badges-store";
import { apiFetch } from "@/lib/api-client";
import type { BadgeModel, UserSearchResult } from "@/components/features/badges/_components/badge-models";

interface AdminUsersSearchResponse {
  data: UserSearchResult[];
  total: number;
}

interface UseBadgesOptions {
  autoLoad?: boolean;
}

export function useBadges(options: UseBadgesOptions = {}) {
  const { autoLoad = true } = options;

  const store = useBadgesStore();
  const {
    badges,
    isLoading,
    error,
    setBadges,
    setLoading,
    setError,
    grantOpen,
    grantUserIdentifier,
    setGrantMatches,
    setGrantSearchLoading,
  } = store;

  const loadBadges = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const data = await apiFetch<BadgeModel[]>("/admin/badges");
      setBadges(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load badges");
    }
  }, [setBadges, setLoading, setError]);

  // Search users for grant dialog
  useEffect(() => {
    if (!grantOpen) {
      setGrantMatches([]);
      setGrantSearchLoading(false);
      return;
    }

    const query = grantUserIdentifier.trim();
    if (query.length < 2) {
      setGrantMatches([]);
      setGrantSearchLoading(false);
      return;
    }

    const timer = setTimeout(async () => {
      setGrantSearchLoading(true);
      try {
        const response = await apiFetch<AdminUsersSearchResponse>(
          `/admin/users?limit=8&offset=0&status=active&q=${encodeURIComponent(query)}`
        );
        setGrantMatches(response.data ?? []);
      } catch {
        setGrantMatches([]);
      } finally {
        setGrantSearchLoading(false);
      }
    }, 250);

    return () => clearTimeout(timer);
  }, [grantOpen, grantUserIdentifier, setGrantMatches, setGrantSearchLoading]);

  // Auto-load on mount
  useEffect(() => {
    if (autoLoad) {
      void loadBadges();
    }
  }, [autoLoad, loadBadges]);

  return {
    ...store,
    loadBadges,
    refresh: loadBadges,
  };
}
