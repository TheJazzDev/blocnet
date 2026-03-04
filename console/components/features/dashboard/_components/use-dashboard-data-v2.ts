'use client';

import { useEffect, useMemo, useState } from 'react';
import type {
  AdminWalletHealth,
  AuditLog,
  EdgeBriefResponse,
  EdgeExplainResponse,
} from '@/lib/api-client';
import { clientApi } from '@/lib/api-client';
import { useStats } from '@/lib/hooks';
import {
  ACTIVITY_PAGE_SIZE,
  TELEMETRY_LOG_LIMIT,
  buildEdgeTelemetry,
} from './dashboard-utils';

/**
 * Refactored dashboard hook using Zustand for stats management
 * This demonstrates how to migrate from useState to Zustand
 */
export function useDashboardDataV2() {
  // Use Zustand store for stats instead of local useState
  const { stats, isLoading: statsLoading, refresh: refreshStats } = useStats();

  // Keep local state for dashboard-specific data
  const [walletHealth, setWalletHealth] = useState<AdminWalletHealth | null>(null);
  const [activityLogs, setActivityLogs] = useState<AuditLog[]>([]);
  const [telemetryLogs, setTelemetryLogs] = useState<AuditLog[]>([]);
  const [edgeBrief, setEdgeBrief] = useState<EdgeBriefResponse | null>(null);
  const [edgeExplain, setEdgeExplain] = useState<EdgeExplainResponse | null>(null);
  const [edgeExplainLoading, setEdgeExplainLoading] = useState(false);
  const [selectedDecisionId, setSelectedDecisionId] = useState<string | null>(null);
  const [activityPage, setActivityPage] = useState(0);
  const [activityHasNext, setActivityHasNext] = useState(false);
  const [activityLoading, setActivityLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);

  async function loadDashboard(withSpinner: boolean) {
    if (withSpinner) {
      // Stats loading is handled by the store
    } else {
      setRefreshing(true);
    }
    setLoadError(null);

    try {
      const [firstLogs, telemetry, edge, wallet] = await Promise.all([
        clientApi.listAuditLog(ACTIVITY_PAGE_SIZE, 0),
        clientApi.listAuditLog(TELEMETRY_LOG_LIMIT, 0),
        clientApi.getMyEdgeBrief(7),
        clientApi.getWalletHealth().catch(() => null),
        refreshStats(), // Refresh stats from store
      ]);

      setWalletHealth(wallet);
      setActivityLogs(firstLogs);
      setTelemetryLogs(telemetry);
      setActivityPage(0);
      setActivityHasNext(firstLogs.length === ACTIVITY_PAGE_SIZE);
      setEdgeBrief(edge);
    } catch (error: unknown) {
      setWalletHealth(null);
      setActivityLogs([]);
      setTelemetryLogs([]);
      setActivityPage(0);
      setActivityHasNext(false);
      setEdgeBrief(null);
      setLoadError(
        error instanceof Error ? error.message : 'Failed to load dashboard data',
      );
    } finally {
      setRefreshing(false);
    }
  }

  useEffect(() => {
    void loadDashboard(true);
  }, []);

  useEffect(() => {
    if (!edgeBrief || selectedDecisionId || edgeBrief.topDecisions.length === 0) {
      return;
    }
    void openEdgeDecision(edgeBrief.topDecisions[0].decisionId);
  }, [edgeBrief, selectedDecisionId]);

  async function openEdgeDecision(decisionId: string) {
    setSelectedDecisionId(decisionId);
    setEdgeExplainLoading(true);
    try {
      const explain = await clientApi.getMyEdgeExplain(decisionId);
      setEdgeExplain(explain);
    } catch {
      setEdgeExplain(null);
    } finally {
      setEdgeExplainLoading(false);
    }
  }

  async function loadActivityPage(nextPage: number) {
    if (nextPage < 0 || statsLoading || activityLoading) {
      return;
    }

    setActivityLoading(true);
    setLoadError(null);
    try {
      const offset = nextPage * ACTIVITY_PAGE_SIZE;
      const nextLogs = await clientApi.listAuditLog(ACTIVITY_PAGE_SIZE, offset);
      setActivityLogs(nextLogs);
      setActivityPage(nextPage);
      setActivityHasNext(nextLogs.length === ACTIVITY_PAGE_SIZE);
    } catch (error: unknown) {
      setLoadError(
        error instanceof Error ? error.message : 'Failed to load activity page',
      );
    } finally {
      setActivityLoading(false);
    }
  }

  const edgeAuditEvents = useMemo(
    () => telemetryLogs.filter((event) => event.action.startsWith('edge.')),
    [telemetryLogs],
  );

  const edgeTelemetry = useMemo(
    () => buildEdgeTelemetry(edgeAuditEvents),
    [edgeAuditEvents],
  );

  return {
    stats, // From Zustand store
    walletHealth,
    activityLogs,
    edgeBrief,
    edgeExplain,
    edgeExplainLoading,
    selectedDecisionId,
    activityPage,
    activityHasNext,
    activityLoading,
    loading: statsLoading,
    refreshing,
    loadError,
    edgeTelemetry,
    loadDashboard,
    openEdgeDecision,
    loadActivityPage,
  };
}
