/**
 * Client-side API fetcher — reads token from cookie, no `cookies()` import
 * so it works in "use client" components.
 */

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3080/api";

function getToken(): string {
  if (typeof document === "undefined") return "";
  return (
    document.cookie
      .split("; ")
      .find((r) => r.startsWith("admin_token="))
      ?.split("=")[1] ?? ""
  );
}

export async function apiFetch<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(`API ${res.status}: ${text}`);
  }

  return res.json() as Promise<T>;
}

// ─── Re-export types from shared api.ts ───────────────────────────────────────
export type {
  AdminStats,
  AdminUser,
  AdminUsersResponse,
  Project,
  AdminApplication,
  ProjectProposal,
  AuditLog,
} from "./api";

// ─── Client-side API calls ────────────────────────────────────────────────────
import type {
  AdminStats,
  AdminUsersResponse,
  Project,
  AdminApplication,
  ProjectProposal,
  AuditLog,
} from "./api";

export const clientApi = {
  getStats: () => apiFetch<AdminStats>("/admin/users/stats"),

  listUsers: (params?: { limit?: number; offset?: number; role?: string }) => {
    const q = new URLSearchParams();
    if (params?.limit) q.set("limit", String(params.limit));
    if (params?.offset) q.set("offset", String(params.offset));
    if (params?.role) q.set("role", params.role);
    return apiFetch<AdminUsersResponse>(`/admin/users?${q}`);
  },

  listProjects: () => apiFetch<Project[]>("/projects"),

  listAdminApplications: () => apiFetch<AdminApplication[]>("/admin-applications"),

  listProjectProposals: () => apiFetch<ProjectProposal[]>("/project-proposals"),

  listAuditLog: (limit = 100) => apiFetch<AuditLog[]>(`/audit-log?limit=${limit}`),

  updateProject: (id: string, body: { status: string }) =>
    apiFetch(`/projects/${id}`, { method: "PATCH", body: JSON.stringify(body) }),

  reviewAdminApplication: (id: string, body: { status: "approved" | "rejected" }) =>
    apiFetch(`/admin-applications/${id}/review`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  reviewProjectProposal: (id: string, body: { status: "approved" | "rejected" }) =>
    apiFetch(`/project-proposals/${id}/review`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  promoteToAdmin: (userId: string) =>
    apiFetch(`/roles/admins/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({}),
    }),

  promoteToHunter: (userId: string) =>
    apiFetch(`/roles/hunters/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({}),
    }),
};
