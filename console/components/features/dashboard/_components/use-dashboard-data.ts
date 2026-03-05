'use client';

import { useEffect, useMemo, useState } from 'react';
import type {
  AdminWalletHealth,
  AuditLog,
  EdgeBriefResponse,
  EdgeExplainResponse,
} from '@/lib/api-client';
import { clientApi } from '@/lib/api-client';
import { useStatsQuery } from '@/lib/hooks/queries';
import {
  ACTIVITY_PAGE_SIZE,
  TELEMETRY_LOG_LIMIT,
  buildEdgeTelemetry,
} from './dashboard-utils';

export function useDashboardData() {
  // Use TanStack Query for stats with auto-refresh every 30 seconds
  const {
    data: stats,
    isLoading: statsLoading,
    error: statsError,
    refetch: refetchStats,
  } = useStatsQuery({ refetchInterval: 30_000 });

  const [walletHealth, setWalletHealth] = useState<AdminWalletHealth | null>(
    null,
  );
  const [activityLogs, setActivityLogs] = useState<AuditLog[]>([]);
  const [telemetryLogs, setTelemetryLogs] = useState<AuditLog[]>([]);
  const [edgeBrief, setEdgeBrief] = useState<EdgeBriefResponse | null>(null);
  const [edgeExplain, setEdgeExplain] = useState<EdgeExplainResponse | null>(
    null,
  );
  const [edgeExplainLoading, setEdgeExplainLoading] = useState(false);
  const [selectedDecisionId, setSelectedDecisionId] = useState<string | null>(
    null,
  );
  const [activityPage, setActivityPage] = useState(0);
  const [activityHasNext, setActivityHasNext] = useState(false);
  const [activityLoading, setActivityLoading] = useState(false);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);

  async function loadDashboard(withSpinner: boolean) {
    if (withSpinner) {
      setLoading(true);
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
      ]);

      // Stats come from TanStack Query, refetch if needed
      if (!withSpinner) {
        void refetchStats();
      }

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
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    void loadDashboard(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
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
    if (nextPage < 0 || loading || activityLoading) {
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
    stats: stats ?? null,
    walletHealth,
    activityLogs,
    edgeBrief,
    edgeExplain,
    edgeExplainLoading,
    selectedDecisionId,
    activityPage,
    activityHasNext,
    activityLoading,
    loading: loading || statsLoading,
    refreshing,
    loadError: loadError || (statsError ? 'Failed to load stats' : null),
    edgeTelemetry,
    loadDashboard,
    openEdgeDecision,
    loadActivityPage,
  };
}
