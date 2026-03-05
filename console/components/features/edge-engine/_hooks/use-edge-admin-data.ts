"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  clientApi,
  type AdminEdgeConfig,
  type AdminEdgeOverviewResponse,
  type AuditLog,
} from "@/lib/api-client";
import { dedupeTopDecisions } from "../_lib/edge-admin";

export type EdgeConfigNotice = {
  type: "success" | "error";
  message: string;
};

function normalizeMlUrl(rawUrl: string): string | null {
  const trimmed = rawUrl.trim();
  if (!trimmed) return null;

  const hasProtocol = /^[a-zA-Z][a-zA-Z\d+\-.]*:\/\//.test(trimmed);
  const candidate = hasProtocol ? trimmed : `http://${trimmed}`;

  try {
    const parsed = new URL(candidate);
    if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
      return null;
    }
    return parsed.toString().replace(/\/$/, "");
  } catch {
    return null;
  }
}

function getReadableError(error: unknown): string {
  if (!(error instanceof Error)) {
    return "Unable to save configuration right now.";
  }

  const message = error.message.trim();
  const apiPrefix = /^API\s+\d+:\s*/i;
  if (!apiPrefix.test(message)) {
    return message;
  }

  const payload = message.replace(apiPrefix, "");
  try {
    const parsed = JSON.parse(payload) as {
      message?: string | string[];
      error?: string;
      statusCode?: number;
    };
    if (Array.isArray(parsed.message) && parsed.message.length > 0) {
      const first = parsed.message[0];
      if (first === "mlUrl must be a URL address") {
        return "ML Service URL is invalid. Use a full URL like http://localhost:8083.";
      }
      return first;
    }
    if (typeof parsed.message === "string" && parsed.message.trim().length > 0) {
      return parsed.message;
    }
    if (typeof parsed.error === "string" && parsed.error.trim().length > 0) {
      return parsed.error;
    }
    return "Unable to save configuration right now.";
  } catch {
    return message;
  }
}

export function useEdgeAdminData(initialWindowDays = 7) {
  const [windowDays, setWindowDays] = useState(initialWindowDays);
  const [overview, setOverview] = useState<AdminEdgeOverviewResponse | null>(null);
  const [edgeConfig, setEdgeConfig] = useState<AdminEdgeConfig | null>(null);
  const [auditLog, setAuditLog] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [configSaving, setConfigSaving] = useState(false);
  const [recomputeRunning, setRecomputeRunning] = useState(false);
  const [configStatus, setConfigStatus] = useState<EdgeConfigNotice | null>(null);
  const [error, setError] = useState<string | null>(null);
  const hasLoadedOnce = useRef(false);

  const loadData = useCallback(
    async ({
      withSpinner,
      nextWindowDays,
    }: {
      withSpinner: boolean;
      nextWindowDays: number;
    }) => {
      if (withSpinner) {
        setLoading(true);
      } else {
        setRefreshing(true);
      }
      setError(null);

      try {
        const [overviewRes, configRes, logsRes] = await Promise.all([
          clientApi.getAdminEdgeOverview(nextWindowDays, 24, 8, 12),
          clientApi.getAdminEdgeConfig(),
          clientApi.listAuditLog(250),
        ]);
        setOverview(dedupeTopDecisions(overviewRes));
        setEdgeConfig(configRes);
        setAuditLog(logsRes);
      } catch (e: unknown) {
        setOverview(null);
        setEdgeConfig(null);
        setAuditLog([]);
        setError(e instanceof Error ? e.message : "Failed to load Edge Engine data");
      } finally {
        setLoading(false);
        setRefreshing(false);
      }
    },
    [],
  );

  useEffect(() => {
    void loadData({ withSpinner: true, nextWindowDays: initialWindowDays }).then(() => {
      hasLoadedOnce.current = true;
    });
  }, [initialWindowDays, loadData]);

  useEffect(() => {
    if (!hasLoadedOnce.current) return;
    void loadData({ withSpinner: false, nextWindowDays: windowDays });
  }, [windowDays, loadData]);

  const refresh = useCallback(async () => {
    await loadData({ withSpinner: false, nextWindowDays: windowDays });
  }, [loadData, windowDays]);

  const saveEdgeConfig = useCallback(async () => {
    if (!edgeConfig) return;
    setConfigSaving(true);
    setConfigStatus(null);
    try {
      const normalizedMlUrl = normalizeMlUrl(edgeConfig.mlUrl);
      if (edgeConfig.mlEnabled && !normalizedMlUrl) {
        setConfigStatus({
          type: "error",
          message: "ML Service URL is invalid. Use a full URL like http://localhost:8083.",
        });
        setConfigSaving(false);
        return;
      }

      const next = await clientApi.updateAdminEdgeConfig({
        enabled: edgeConfig.enabled,
        mlEnabled: edgeConfig.mlEnabled,
        mlUrl: normalizedMlUrl ?? undefined,
        mlTimeout: edgeConfig.mlTimeout,
        mlProvider: edgeConfig.mlProvider,
        mlWebSearch: edgeConfig.mlWebSearch,
        mlOllamaModel: edgeConfig.mlOllamaModel,
        mlOllamaEmbeddingModel: edgeConfig.mlOllamaEmbeddingModel,
        mlOllamaTimeout: edgeConfig.mlOllamaTimeout,
        mlGroqModel: edgeConfig.mlGroqModel,
        mlGeminiModel: edgeConfig.mlGeminiModel,
        mlGeminiEmbeddingModel: edgeConfig.mlGeminiEmbeddingModel,
        mlCacheTtl: edgeConfig.mlCacheTtl,
        mlMaxContentLength: edgeConfig.mlMaxContentLength,
      });
      setEdgeConfig(next);
      setConfigStatus(
        {
          type: "success",
          message: `Configuration saved. BEE is ${next.enabled ? "enabled" : "disabled"} and ML is ${
            next.mlEnabled ? "enabled" : "disabled"
          }.`,
        },
      );
      await loadData({ withSpinner: false, nextWindowDays: windowDays });
    } catch (e: unknown) {
      setConfigStatus({
        type: "error",
        message: getReadableError(e),
      });
    } finally {
      setConfigSaving(false);
    }
  }, [edgeConfig, loadData, windowDays]);

  const recomputeEdgeDecisions = useCallback(async () => {
    setRecomputeRunning(true);
    setConfigStatus(null);
    try {
      const result = await clientApi.recomputeAdminEdge({
        userLimit: 5,
        windowDays,
      });
      setConfigStatus({
        type: "success",
        message: `Recompute complete. ${result.successfulUsers}/${result.processedUsers} users succeeded with ${result.totalSignals} total signals.`,
      });
      await loadData({ withSpinner: false, nextWindowDays: windowDays });
    } catch (e: unknown) {
      setConfigStatus({
        type: "error",
        message: getReadableError(e),
      });
    } finally {
      setRecomputeRunning(false);
    }
  }, [loadData, windowDays]);

  return {
    windowDays,
    setWindowDays,
    overview,
    edgeConfig,
    setEdgeConfig,
    auditLog,
    loading,
    refreshing,
    configSaving,
    recomputeRunning,
    configStatus,
    error,
    refresh,
    saveEdgeConfig,
    recomputeEdgeDecisions,
  };
}
