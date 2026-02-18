/**
 * Server-side API client for the Blocnet admin panel.
 * Uses the stored Supabase token from cookies to authenticate requests.
 */
import { cookies } from "next/headers";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3080/api";

async function getToken(): Promise<string | null> {
  const store = await cookies();
  return store.get("admin_token")?.value ?? null;
}

async function apiFetch<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const token = await getToken();

  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
    // Disable Next.js caching for admin data
    cache: "no-store",
  });

  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(`API ${res.status}: ${text}`);
  }

  return res.json() as Promise<T>;
}

// ─── Types ────────────────────────────────────────────────────────────────────

export interface AdminStats {
  totalProjects: number;
  totalUsers: number;
  pendingAdminApps: number;
  totalUpdates: number;
  totalComments: number;
  activeHunters: number;
  pendingProposals: number;
  totalTags: number;
}

export interface AdminUser {
  id: string;
  email: string;
  displayName: string | null;
  avatarUrl: string | null;
  roles: string[];
  projectsAssigned: number;
  updatesPosted: number;
  createdAt: string;
}

export interface AdminUsersResponse {
  data: AdminUser[];
  total: number;
  limit: number;
  offset: number;
}

export interface Project {
  id: string;
  name: string;
  symbol: string | null;
  status: "active" | "paused" | "archived";
  primaryTag: string | null;
  primaryTagId: string;
  followersCount: number;
  updatesCount: number;
  createdAt: string;
}

export interface AdminApplication {
  id: string;
  userId: string;
  /** Backend includes the user as `user` */
  user: {
    id: string;
    email: string;
    displayName: string | null;
    avatarUrl: string | null;
  };
  targetRole: "admin" | "hunter";
  reason: string;
  status: "pending" | "approved" | "rejected";
  createdAt: string;
  reviewedAt: string | null;
}

export interface ProjectProposal {
  id: string;
  name: string;
  symbol: string | null;
  description: string;
  reason: string | null;
  primaryTag: { id: string; name: string } | null;
  applicant: {
    id: string;
    email: string;
    displayName: string | null;
  };
  status: "pending" | "approved" | "rejected";
  createdAt: string;
  reviewedAt: string | null;
}

export interface AuditLog {
  id: string;
  action: string;
  actor: {
    id: string;
    email: string;
    displayName: string | null;
  } | null;
  resourceType: string;
  resourceId: string | null;
  description: string | null;
  metadata: Record<string, unknown>;
  createdAt: string;
}

// ─── API Functions ────────────────────────────────────────────────────────────

export const api = {
  /** GET /admin/users/stats */
  getStats: () => apiFetch<AdminStats>("/admin/users/stats"),

  /** GET /admin/users */
  listUsers: (params?: { limit?: number; offset?: number; role?: string }) => {
    const q = new URLSearchParams();
    if (params?.limit) q.set("limit", String(params.limit));
    if (params?.offset) q.set("offset", String(params.offset));
    if (params?.role) q.set("role", params.role);
    return apiFetch<AdminUsersResponse>(`/admin/users?${q}`);
  },

  /** GET /projects */
  listProjects: (params?: { status?: string }) => {
    const q = new URLSearchParams();
    if (params?.status && params.status !== "all") q.set("status", params.status);
    return apiFetch<Project[]>(`/projects?${q}`);
  },

  /** PATCH /projects/:id */
  updateProject: (id: string, body: { status: string }) =>
    apiFetch(`/projects/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  /** GET /admin-applications */
  listAdminApplications: () =>
    apiFetch<AdminApplication[]>("/admin-applications"),

  /** PATCH /admin-applications/:id/review */
  reviewAdminApplication: (
    id: string,
    body: { status: "approved" | "rejected"; note?: string }
  ) =>
    apiFetch(`/admin-applications/${id}/review`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  /** GET /project-proposals */
  listProjectProposals: () =>
    apiFetch<ProjectProposal[]>("/project-proposals"),

  /** PATCH /project-proposals/:id/review */
  reviewProjectProposal: (
    id: string,
    body: { status: "approved" | "rejected"; note?: string }
  ) =>
    apiFetch(`/project-proposals/${id}/review`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  /** GET /audit-log */
  listAuditLog: (limit = 100) =>
    apiFetch<AuditLog[]>(`/audit-log?limit=${limit}`),

  /** POST /roles/admins/:userId/promote */
  promoteToAdmin: (userId: string, note?: string) =>
    apiFetch(`/roles/admins/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  /** POST /roles/hunters/:userId/promote */
  promoteToHunter: (userId: string, note?: string) =>
    apiFetch(`/roles/hunters/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),
};
