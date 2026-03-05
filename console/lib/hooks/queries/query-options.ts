import type { UseQueryOptions } from "@tanstack/react-query";

/**
 * Common query option presets for different use cases
 */

export const queryOptions = {
  /**
   * Fast-changing data that should always be fresh (e.g., real-time stats)
   */
  realtime: {
    staleTime: 0,
    refetchInterval: 10_000, // Refetch every 10 seconds
    refetchOnWindowFocus: true,
  } satisfies Partial<UseQueryOptions>,

  /**
   * Moderate caching for data that changes occasionally (e.g., user lists)
   */
  standard: {
    staleTime: 30_000, // 30 seconds
    refetchOnWindowFocus: true,
  } satisfies Partial<UseQueryOptions>,

  /**
   * Long-term caching for rarely changing data (e.g., roles matrix, settings)
   */
  static: {
    staleTime: 5 * 60 * 1000, // 5 minutes
    refetchOnWindowFocus: false,
    refetchOnMount: false,
  } satisfies Partial<UseQueryOptions>,

  /**
   * One-time fetch, no automatic refetching (e.g., user profile details)
   */
  once: {
    staleTime: Infinity,
    refetchOnWindowFocus: false,
    refetchOnMount: false,
  } satisfies Partial<UseQueryOptions>,

  /**
   * No caching, always fetch fresh (e.g., OTP codes, sensitive data)
   */
  noCache: {
    staleTime: 0,
    gcTime: 0, // v5: renamed from cacheTime
    refetchOnWindowFocus: false,
    refetchOnMount: true,
  } satisfies Partial<UseQueryOptions>,
} as const;
