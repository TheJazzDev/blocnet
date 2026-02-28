import { apiFetch, toQuery } from "./api-client-http";
import type {
  AdminApplication,
  AuditLog,
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
};
