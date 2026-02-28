import { apiFetch, toQuery } from "./api-client-http";
import type {
  AdminEdgeConfig,
  AdminEdgeRecomputeResponse,
  AdminEdgeOverviewResponse,
  EdgeBriefResponse,
  EdgeExplainResponse,
  EdgeFeedResponse,
  EdgeFeedbackResponse,
} from "./api-client-edge-types";

export const edgeApi = {
  getMyEdgeFeed: (limit = 30, cursor?: string) =>
    apiFetch<EdgeFeedResponse>(`/me/edge/feed${toQuery({ limit, cursor })}`),

  getMyEdgeBrief: (windowDays = 7) =>
    apiFetch<EdgeBriefResponse>(`/me/edge/brief${toQuery({ windowDays })}`),

  getMyEdgeExplain: (decisionId: string) =>
    apiFetch<EdgeExplainResponse>(
      `/me/edge/explain/${encodeURIComponent(decisionId)}`,
    ),

  getAdminEdgeOverview: (
    windowDays = 7,
    decisionsLimit = 20,
    projectsLimit = 8,
    reasonLimit = 10,
  ) =>
    apiFetch<AdminEdgeOverviewResponse>(
      `/admin/edge/overview${toQuery({ windowDays, decisionsLimit, projectsLimit, reasonLimit })}`,
    ),

  getAdminEdgeConfig: () => apiFetch<AdminEdgeConfig>("/admin/edge/config"),

  updateAdminEdgeConfig: (body: Partial<Omit<AdminEdgeConfig, "id" | "updatedAt">>) =>
    apiFetch<AdminEdgeConfig>("/admin/edge/config", {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  recomputeAdminEdge: (body?: {
    userId?: string;
    userLimit?: number;
    windowDays?: number;
  }) =>
    apiFetch<AdminEdgeRecomputeResponse>("/admin/edge/recompute", {
      method: "POST",
      body: JSON.stringify(body ?? {}),
    }),

  sendMyEdgeFeedback: (body: {
    decisionId: string;
    action: "act" | "watch" | "ignore";
    context?: Record<string, unknown>;
  }) =>
    apiFetch<EdgeFeedbackResponse>("/me/edge/feedback", {
      method: "POST",
      body: JSON.stringify(body),
    }),
};
