import { apiFetch, toQuery } from "./api-client-http";
import type {
  AdminApplication,
  AuditLog,
  CommunityModerationReportsResponse,
  CommunityModerationUserState,
  OpsEvent,
  OpsEventProvider,
  OpsEventSource,
  OpsEventStatus,
  ProjectProposal,
} from "./api";

export const governanceApi = {
  listAdminApplications: () =>
    apiFetch<AdminApplication[]>("/admin-applications"),

  reviewAdminApplication: (
    id: string,
    body: { status: "approved" | "rejected"; note?: string },
  ) =>
    apiFetch(`/admin-applications/${id}/review`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listProjectProposals: () => apiFetch<ProjectProposal[]>("/project-proposals"),

  reviewProjectProposal: (
    id: string,
    body: { status: "approved" | "rejected"; note?: string },
  ) =>
    apiFetch(`/project-proposals/${id}/review`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listAuditLog: (limit = 100, offset = 0) =>
    apiFetch<AuditLog[]>(`/audit-log${toQuery({ limit, offset })}`),

  listOpsEvents: (params?: {
    q?: string;
    source?: "all" | OpsEventSource;
    provider?: "all" | OpsEventProvider;
    status?: "all" | OpsEventStatus;
    from?: string;
    to?: string;
    limit?: number;
    offset?: number;
  }) =>
    apiFetch<OpsEvent[]>(
      `/audit-log/ops-events${toQuery({
        q: params?.q,
        source: params?.source,
        provider: params?.provider,
        status: params?.status,
        from: params?.from,
        to: params?.to,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  listCommunityReports: (params?: {
    q?: string;
    status?: "open" | "resolved" | "dismissed";
    targetType?: "community_post" | "community_comment" | "user_profile";
    limit?: number;
    offset?: number;
  }) =>
    apiFetch<CommunityModerationReportsResponse>(
      `/admin/community-moderation/reports${toQuery({
        q: params?.q,
        status: params?.status,
        targetType: params?.targetType,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  reviewCommunityReport: (
    reportId: string,
    body: { status: "resolved" | "dismissed"; note?: string },
  ) =>
    apiFetch(`/admin/community-moderation/reports/${reportId}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  getCommunityModerationUserState: (userId: string) =>
    apiFetch<CommunityModerationUserState>(
      `/admin/community-moderation/users/${userId}/state`,
    ),

  issueCommunityWarning: (
    userId: string,
    body: { reason: string; reportId?: string },
  ) =>
    apiFetch<CommunityModerationUserState>(
      `/admin/community-moderation/users/${userId}/warnings`,
      {
        method: "POST",
        body: JSON.stringify(body),
      },
    ),

  applyCommunityMute: (
    userId: string,
    body: { durationHours: number; reason: string; reportId?: string },
  ) =>
    apiFetch<CommunityModerationUserState>(
      `/admin/community-moderation/users/${userId}/mutes`,
      {
        method: "POST",
        body: JSON.stringify(body),
      },
    ),

  applyCommunitySuspension: (
    userId: string,
    body: { durationHours: number; reason: string; reportId?: string },
  ) =>
    apiFetch<CommunityModerationUserState>(
      `/admin/community-moderation/users/${userId}/suspensions`,
      {
        method: "POST",
        body: JSON.stringify(body),
      },
    ),

  applyCommunityRestrictions: (
    userId: string,
    body: {
      postingHours?: number;
      commentingHours?: number;
      reason: string;
      reportId?: string;
    },
  ) =>
    apiFetch<CommunityModerationUserState>(
      `/admin/community-moderation/users/${userId}/restrictions`,
      {
        method: "POST",
        body: JSON.stringify(body),
      },
    ),

  clearCommunityRestrictions: (
    userId: string,
    body: { reason: string; reportId?: string },
  ) =>
    apiFetch<CommunityModerationUserState>(
      `/admin/community-moderation/users/${userId}/restrictions/clear`,
      {
        method: "POST",
        body: JSON.stringify(body),
      },
    ),
};
